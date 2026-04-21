import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/capture/save_session_usecase.dart';
import '../../services/video/frame_extractor.dart';
import '../../services/video/swing_detector.dart';

/// Result of splitting a long recording into N per-swing sessions.
class SplitLongRecordingResult {
  const SplitLongRecordingResult({
    required this.sessionIds,
    required this.windows,
  });

  final List<String> sessionIds;
  final List<SwingWindow> windows;
}

/// FR-005: detect swings in a long recording and save each as its own session.
class SplitLongRecording {
  const SplitLongRecording({
    required this.frameExtractor,
    required this.saveSession,
    this.detector = const SwingDetector(),
  });

  final FrameExtractor frameExtractor;
  final SaveSession saveSession;
  final SwingDetector detector;

  /// Gate to support platform-only builds; iOS support is not wired yet.
  bool get isSupported => Platform.isAndroid;

  Future<List<String>> call({
    required File source,
    required String playerId,
    String? club,
    String? tournamentId,
    int padBeforeMs = 2000,
    int padAfterMs = 2000,
    int totalDurationMs = 0,
    int fps = 30,
  }) async {
    if (!isSupported) {
      throw UnsupportedError(
        'Long record / auto-split is Android-only for now.',
      );
    }
    if (!await source.exists()) {
      throw StateError('Source video does not exist: ${source.path}');
    }

    // 1. Motion-magnitude samples via native extractor.
    final samples = await frameExtractor.motionMagnitudes(
      videoPath: source.path,
      durationMs: totalDurationMs,
      sampleFps: 5,
    );

    // 2. Detect swing windows.
    final windows = detector.detect(samples);
    if (windows.isEmpty) return const [];

    // Estimate total duration from the last sample if caller didn't know it.
    final total = totalDurationMs > 0
        ? totalDurationMs
        : (samples.isNotEmpty ? samples.last.timestampMs + 500 : 0);

    final tmp = await getTemporaryDirectory();
    final trimDir = Directory(p.join(tmp.path, 'golfbuddy_trims'));
    if (!await trimDir.exists()) {
      await trimDir.create(recursive: true);
    }

    final sessionIds = <String>[];
    var idx = 0;
    for (final w in windows) {
      final startMs = math.max(0, w.startMs - padBeforeMs);
      final endMs =
          total > 0 ? math.min(total, w.endMs + padAfterMs) : w.endMs + padAfterMs;
      if (endMs <= startMs) continue;

      final clipName =
          'clip_${DateTime.now().microsecondsSinceEpoch}_$idx.mp4';
      final clipPath = p.join(trimDir.path, clipName);

      final trimmedPath = await frameExtractor.trimClip(
        videoPath: source.path,
        startMs: startMs,
        endMs: endMs,
        outputPath: clipPath,
      );

      final sessionId = await saveSession.call(
        SaveSessionInput(
          tempVideo: File(trimmedPath),
          playerId: playerId,
          capturedAt: DateTime.now(),
          durationMs: endMs - startMs,
          fps: fps,
          club: club,
          tournamentId: tournamentId,
        ),
      );
      sessionIds.add(sessionId);
      idx++;
    }

    // Drop the long source recording; it's been sliced into N sessions.
    try {
      if (await source.exists()) await source.delete();
    } catch (_) {
      // Best-effort cleanup.
    }

    return sessionIds;
  }
}
