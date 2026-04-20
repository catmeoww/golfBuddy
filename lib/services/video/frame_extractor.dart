import 'dart:io';

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

// TEMPORARY: ffmpeg_kit_flutter_min was delisted from Maven by upstream.
// Frame extraction is disabled until we swap in a maintained fork or
// use MediaCodec/AVFoundation directly. AnalyzeSwing catches this and
// marks the session as `failed` so the rest of the app keeps working.
class FrameExtractor {
  const FrameExtractor({this.capFps = 60});

  final int capFps;

  Future<List<ExtractedFrame>> extract({
    required String videoPath,
    required int sourceFps,
    required String sessionId,
  }) async {
    throw FrameExtractorException(
      'Frame extraction is temporarily disabled (ffmpeg dep removed). '
      'Analysis will resume once an alternative is wired in.',
    );
  }

  Future<void> cleanup(String sessionId) async {
    final dir = Directory('/tmp/golfbuddy_frames/$sessionId');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
