import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import 'swing_detector.dart';

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

/// LLD §4 — per-frame extractor. Android path uses a MediaCodec-backed
/// platform channel; other platforms currently throw.
class FrameExtractor {
  const FrameExtractor({this.capFps = 60, this.maxFrames = 60});

  final int capFps;
  final int maxFrames;

  static const MethodChannel _channel =
      MethodChannel('app.golfbuddy/frame_extractor');

  Future<List<ExtractedFrame>> extract({
    required String videoPath,
    required int sourceFps,
    required int durationMs,
    required String sessionId,
  }) async {
    if (!Platform.isAndroid) {
      throw FrameExtractorException(
        'Frame extraction is only implemented on Android for now.',
      );
    }
    final targetFps = _computeTargetFps(
      sourceFps: sourceFps,
      durationMs: durationMs,
    );
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('extract', {
        'videoPath': videoPath,
        'sessionId': sessionId,
        'targetFps': targetFps,
        'durationMs': durationMs,
        'capFps': capFps,
        'maxFrames': maxFrames,
      });
      if (raw == null) return const [];
      return raw
          .cast<Map<dynamic, dynamic>>()
          .map(
            (e) => ExtractedFrame(
              frameIndex: (e['frameIndex'] as num).toInt(),
              timestampMs: (e['timestampMs'] as num).toInt(),
              filePath: e['filePath'] as String,
            ),
          )
          .toList(growable: false);
    } on PlatformException catch (e) {
      throw FrameExtractorException(e.message ?? e.code);
    } on MissingPluginException catch (e) {
      throw FrameExtractorException(
        e.message ?? 'Frame extractor channel not registered.',
      );
    }
  }

  Future<void> cleanup(String sessionId) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('cleanup', {'sessionId': sessionId});
    } on PlatformException {
      // best-effort cleanup
    } on MissingPluginException {
      // channel not available (tests); ignore
    }
  }

  /// Returns per-pair frame motion magnitudes for [videoPath], sampled at
  /// [sampleFps] frames-per-second. Android-only.
  Future<List<MotionSample>> motionMagnitudes({
    required String videoPath,
    required int durationMs,
    int sampleFps = 5,
    int downscaleTo = 240,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'Long record / auto-split is Android-only for now.',
      );
    }
    try {
      final raw =
          await _channel.invokeMethod<List<dynamic>>('motionMagnitudes', {
        'videoPath': videoPath,
        'durationMs': durationMs,
        'sampleFps': sampleFps,
        'downscaleTo': downscaleTo,
      });
      if (raw == null) return const [];
      return raw
          .cast<Map<dynamic, dynamic>>()
          .map(
            (e) => MotionSample(
              timestampMs: (e['timestampMs'] as num).toInt(),
              magnitude: (e['magnitude'] as num).toDouble(),
            ),
          )
          .toList(growable: false);
    } on PlatformException catch (e) {
      throw FrameExtractorException(e.message ?? e.code);
    } on MissingPluginException catch (e) {
      throw FrameExtractorException(
        e.message ?? 'Frame extractor channel not registered.',
      );
    }
  }

  /// Losslessly stream-copies the packets in `[startMs, endMs]` from
  /// [videoPath] into [outputPath] using native `MediaMuxer`. Android-only.
  Future<String> trimClip({
    required String videoPath,
    required int startMs,
    required int endMs,
    required String outputPath,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'Long record / auto-split is Android-only for now.',
      );
    }
    try {
      final result = await _channel.invokeMethod<String>('trimClip', {
        'videoPath': videoPath,
        'startMs': startMs,
        'endMs': endMs,
        'outputPath': outputPath,
      });
      if (result == null) {
        throw FrameExtractorException('trimClip returned null');
      }
      return result;
    } on PlatformException catch (e) {
      throw FrameExtractorException(e.message ?? e.code);
    } on MissingPluginException catch (e) {
      throw FrameExtractorException(
        e.message ?? 'Frame extractor channel not registered.',
      );
    }
  }

  int _computeTargetFps({required int sourceFps, required int durationMs}) {
    var fps = sourceFps <= 0 ? 30 : sourceFps;
    fps = math.min(fps, capFps);
    if (fps < 1) fps = 1;
    if (durationMs <= 0) return fps;
    final projected = (durationMs / 1000.0) * fps;
    if (projected > maxFrames) {
      final adjusted = (maxFrames * 1000.0 / durationMs).floor();
      fps = math.max(1, adjusted);
    }
    return fps;
  }
}
