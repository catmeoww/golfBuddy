package app.golfbuddy

import android.content.Context
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import android.media.Image
import android.media.ImageReader
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.util.concurrent.Executors
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import kotlin.math.max
import kotlin.math.min

class FrameExtractorHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "extract" -> handleExtract(call, result)
            "cleanup" -> handleCleanup(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleExtract(call: MethodCall, result: MethodChannel.Result) {
        val videoPath = call.argument<String>("videoPath")
        val sessionId = call.argument<String>("sessionId")
        val targetFps = call.argument<Int>("targetFps")
        val durationMs = (call.argument<Number>("durationMs"))?.toLong()
        val maxFrames = call.argument<Int>("maxFrames")
        if (videoPath == null || sessionId == null || targetFps == null ||
            durationMs == null || maxFrames == null
        ) {
            result.error("bad_args", "Missing extraction arguments", null)
            return
        }
        executor.execute {
            try {
                val frames = extractFrames(
                    videoPath = videoPath,
                    sessionId = sessionId,
                    targetFps = max(1, targetFps),
                    durationMs = durationMs,
                    maxFrames = max(1, maxFrames),
                )
                mainHandler.post { result.success(frames) }
            } catch (t: Throwable) {
                mainHandler.post {
                    result.error("extract_failed", t.message ?: t.toString(), null)
                }
            }
        }
    }

    private fun handleCleanup(call: MethodCall, result: MethodChannel.Result) {
        val sessionId = call.argument<String>("sessionId")
        if (sessionId == null) {
            result.error("bad_args", "Missing sessionId", null)
            return
        }
        executor.execute {
            try {
                val dir = File(File(context.cacheDir, "golfbuddy_frames"), sessionId)
                if (dir.exists()) dir.deleteRecursively()
                mainHandler.post { result.success(null) }
            } catch (t: Throwable) {
                mainHandler.post {
                    result.error("cleanup_failed", t.message ?: t.toString(), null)
                }
            }
        }
    }

    private fun extractFrames(
        videoPath: String,
        sessionId: String,
        targetFps: Int,
        durationMs: Long,
        maxFrames: Int,
    ): List<Map<String, Any>> {
        val scratch = File(File(context.cacheDir, "golfbuddy_frames"), sessionId)
        if (scratch.exists()) scratch.deleteRecursively()
        if (!scratch.mkdirs() && !scratch.isDirectory) {
            throw IllegalStateException("Could not create scratch dir: ${scratch.absolutePath}")
        }

        val extractor = MediaExtractor()
        var decoder: MediaCodec? = null
        var imageReader: ImageReader? = null
        val readerThread = HandlerThread("golfbuddy-frame-reader").apply { start() }
        val readerHandler = Handler(readerThread.looper)
        // Bounded queue so slow JPEG encoding backpressures the decoder.
        val pending = LinkedBlockingQueue<TimedImage>(4)

        try {
            extractor.setDataSource(videoPath)
            val trackIndex = selectVideoTrack(extractor)
                ?: throw IllegalStateException("No video track in $videoPath")
            extractor.selectTrack(trackIndex)
            val format = extractor.getTrackFormat(trackIndex)
            val mime = format.getString(MediaFormat.KEY_MIME)
                ?: throw IllegalStateException("Track has no MIME type")
            val width = format.getInteger(MediaFormat.KEY_WIDTH)
            val height = format.getInteger(MediaFormat.KEY_HEIGHT)

            imageReader = ImageReader.newInstance(
                width,
                height,
                ImageFormat.YUV_420_888,
                4,
            )
            imageReader.setOnImageAvailableListener({ reader ->
                val img = try {
                    reader.acquireNextImage()
                } catch (_: Throwable) {
                    null
                } ?: return@setOnImageAvailableListener
                // Offer-then-close on overflow keeps decoder from stalling forever.
                if (!pending.offer(TimedImage(img, img.timestamp / 1000L), 2, TimeUnit.SECONDS)) {
                    img.close()
                }
            }, readerHandler)

            decoder = MediaCodec.createDecoderByType(mime)
            decoder.configure(format, imageReader.surface, null, 0)
            decoder.start()

            val out = ArrayList<Map<String, Any>>(maxFrames)
            val bufferInfo = MediaCodec.BufferInfo()
            val frameIntervalUs = 1_000_000L / targetFps
            var frameIndex = 0

            while (frameIndex < maxFrames) {
                val targetUs = frameIndex * frameIntervalUs
                val targetMs = targetUs / 1000L
                if (durationMs > 0 && targetMs > durationMs) break

                extractor.seekTo(targetUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
                // Flush so we discard stale frames from the previous seek.
                decoder.flush()
                drainQueue(pending)

                val image = decodeUntil(decoder, extractor, bufferInfo, pending, targetUs)
                    ?: break

                val jpegPath = File(scratch, "frame_%05d.jpg".format(frameIndex)).absolutePath
                writeJpeg(image.image, jpegPath)
                image.image.close()

                out.add(
                    mapOf(
                        "frameIndex" to frameIndex,
                        "timestampMs" to targetMs.toInt(),
                        "filePath" to jpegPath,
                    )
                )
                frameIndex++
            }
            return out
        } finally {
            drainQueue(pending)
            try { decoder?.stop() } catch (_: Throwable) {}
            try { decoder?.release() } catch (_: Throwable) {}
            try { extractor.release() } catch (_: Throwable) {}
            try { imageReader?.close() } catch (_: Throwable) {}
            readerThread.quitSafely()
        }
    }

    private fun selectVideoTrack(extractor: MediaExtractor): Int? {
        for (i in 0 until extractor.trackCount) {
            val f = extractor.getTrackFormat(i)
            val mime = f.getString(MediaFormat.KEY_MIME) ?: continue
            if (mime.startsWith("video/")) return i
        }
        return null
    }

    private fun decodeUntil(
        decoder: MediaCodec,
        extractor: MediaExtractor,
        info: MediaCodec.BufferInfo,
        pending: LinkedBlockingQueue<TimedImage>,
        targetUs: Long,
    ): TimedImage? {
        var sawInputEos = false
        var sawOutputEos = false
        val timeoutUs = 10_000L
        while (!sawOutputEos) {
            if (!sawInputEos) {
                val inIndex = decoder.dequeueInputBuffer(timeoutUs)
                if (inIndex >= 0) {
                    val buf: ByteBuffer = decoder.getInputBuffer(inIndex)
                        ?: continue
                    val size = extractor.readSampleData(buf, 0)
                    if (size < 0) {
                        decoder.queueInputBuffer(
                            inIndex, 0, 0, 0L, MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                        )
                        sawInputEos = true
                    } else {
                        val pts = extractor.sampleTime
                        decoder.queueInputBuffer(inIndex, 0, size, pts, 0)
                        extractor.advance()
                    }
                }
            }

            val outIndex = decoder.dequeueOutputBuffer(info, timeoutUs)
            if (outIndex >= 0) {
                val render = info.size > 0
                decoder.releaseOutputBuffer(outIndex, render)
                if ((info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                    sawOutputEos = true
                }
                if (render) {
                    // Pull the just-rendered frame (ImageReader callback runs async).
                    val img = pending.poll(1, TimeUnit.SECONDS) ?: continue
                    if (img.timestampUs >= targetUs || sawOutputEos || sawInputEos) {
                        return img
                    }
                    img.image.close()
                }
            }
        }
        return null
    }

    private fun drainQueue(pending: LinkedBlockingQueue<TimedImage>) {
        while (true) {
            val img = pending.poll() ?: return
            try { img.image.close() } catch (_: Throwable) {}
        }
    }

    private fun writeJpeg(image: Image, path: String) {
        val nv21 = yuv420ToNv21(image)
        val yuv = YuvImage(nv21, ImageFormat.NV21, image.width, image.height, null)
        FileOutputStream(path).use { fos ->
            val bos = ByteArrayOutputStream()
            yuv.compressToJpeg(Rect(0, 0, image.width, image.height), 90, bos)
            fos.write(bos.toByteArray())
        }
    }

    // Converts a YUV_420_888 Image to NV21 (Y plane followed by interleaved VU).
    private fun yuv420ToNv21(image: Image): ByteArray {
        val width = image.width
        val height = image.height
        val ySize = width * height
        val uvSize = width * height / 2
        val out = ByteArray(ySize + uvSize)

        val yPlane = image.planes[0]
        val uPlane = image.planes[1]
        val vPlane = image.planes[2]

        val yBuf = yPlane.buffer
        val yRowStride = yPlane.rowStride
        val yPixelStride = yPlane.pixelStride
        var offset = 0
        if (yPixelStride == 1 && yRowStride == width) {
            val toCopy = min(yBuf.remaining(), ySize)
            yBuf.get(out, 0, toCopy)
            offset = toCopy
        } else {
            val row = ByteArray(yRowStride)
            for (r in 0 until height) {
                yBuf.position(r * yRowStride)
                val remaining = yBuf.remaining()
                val len = min(yRowStride, remaining)
                yBuf.get(row, 0, len)
                var col = 0
                var i = 0
                while (col < width && i < len) {
                    out[offset++] = row[i]
                    i += yPixelStride
                    col++
                }
            }
        }

        val uBuf = uPlane.buffer
        val vBuf = vPlane.buffer
        val uRowStride = uPlane.rowStride
        val vRowStride = vPlane.rowStride
        val uPixelStride = uPlane.pixelStride
        val vPixelStride = vPlane.pixelStride
        val chromaHeight = height / 2
        val chromaWidth = width / 2

        val uRow = ByteArray(uRowStride)
        val vRow = ByteArray(vRowStride)
        for (r in 0 until chromaHeight) {
            uBuf.position(r * uRowStride)
            val uLen = min(uRowStride, uBuf.remaining())
            uBuf.get(uRow, 0, uLen)
            vBuf.position(r * vRowStride)
            val vLen = min(vRowStride, vBuf.remaining())
            vBuf.get(vRow, 0, vLen)
            var uIdx = 0
            var vIdx = 0
            var col = 0
            while (col < chromaWidth && uIdx < uLen && vIdx < vLen) {
                // NV21 ordering: V first, then U.
                out[offset++] = vRow[vIdx]
                out[offset++] = uRow[uIdx]
                uIdx += uPixelStride
                vIdx += vPixelStride
                col++
            }
        }
        return out
    }

    private data class TimedImage(val image: Image, val timestampUs: Long)
}
