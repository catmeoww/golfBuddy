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

// STUB: see LLD §4 and the pubspec comment. Precise frame extraction is
// blocked on shipping a platform-channel MediaCodec/AVAssetReader path.
// AnalyzeSwing catches this and marks the session as failed so the rest
// of the app (library, capture, annotations, tournaments, playback)
// keeps working.
class FrameExtractor {
  const FrameExtractor({this.capFps = 60, this.maxFrames = 60});

  final int capFps;
  final int maxFrames;

  Future<List<ExtractedFrame>> extract({
    required String videoPath,
    required int sourceFps,
    required int durationMs,
    required String sessionId,
  }) async {
    throw FrameExtractorException(
      'Swing analysis is temporarily unavailable. We\u2019re rebuilding the '
      'frame extractor on a native video decoder; the rest of the app '
      '(capture, library, notes, compare) still works.',
    );
  }

  Future<void> cleanup(String sessionId) async {
    final dir = Directory('/tmp/golfbuddy_frames/$sessionId');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
