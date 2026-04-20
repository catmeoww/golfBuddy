import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ExtractedFrame {
  const ExtractedFrame({
    required this.frameIndex,
    required this.timestampMs,
    required this.filePath,
  });

  final int frameIndex;
  final int timestampMs;
  final String filePath;
}

class FrameExtractorException implements Exception {
  FrameExtractorException(this.message);
  final String message;
  @override
  String toString() => 'FrameExtractorException: $message';
}

/// LLD §4 — extract frames from a recorded swing video via platform
/// decoders. Capped at [capFps] (default 60) to keep pose inference in
/// budget. One file-system read per frame; fine for sub-5s clips.
class FrameExtractor {
  const FrameExtractor({this.capFps = 60});

  final int capFps;

  Future<List<ExtractedFrame>> extract({
    required String videoPath,
    required int sourceFps,
    required int durationMs,
    required String sessionId,
  }) async {
    if (durationMs <= 0) {
      throw FrameExtractorException('durationMs must be > 0');
    }
    final targetFps = sourceFps > capFps ? capFps : sourceFps;
    final frameIntervalMs = (1000 / targetFps).round();
    final outDir = await _scratchDir(sessionId);

    final frames = <ExtractedFrame>[];
    var index = 0;
    for (var t = 0; t <= durationMs; t += frameIntervalMs) {
      final rawPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: outDir.path,
        imageFormat: ImageFormat.JPEG,
        timeMs: t,
        quality: 75,
      );
      if (rawPath == null) continue;
      final target = File(
        p.join(outDir.path, 'frame_${index.toString().padLeft(5, '0')}.jpg'),
      );
      final source = File(rawPath);
      if (source.path != target.path) {
        if (await target.exists()) await target.delete();
        await source.rename(target.path);
      }
      frames.add(
        ExtractedFrame(
          frameIndex: index,
          timestampMs: t,
          filePath: target.path,
        ),
      );
      index++;
    }
    if (frames.isEmpty) {
      throw FrameExtractorException(
        'No frames extracted from $videoPath (durationMs=$durationMs).',
      );
    }
    return frames;
  }

  Future<void> cleanup(String sessionId) async {
    final dir = Directory(await _scratchDirPath(sessionId));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<String> _scratchDirPath(String sessionId) async {
    final root = await getTemporaryDirectory();
    return p.join(root.path, 'golfbuddy_frames', sessionId);
  }

  Future<Directory> _scratchDir(String sessionId) async {
    final dir = Directory(await _scratchDirPath(sessionId));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
    return dir;
  }
}
