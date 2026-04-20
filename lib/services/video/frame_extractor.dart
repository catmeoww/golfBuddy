import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

/// LLD §4 — batch frame extraction via ffmpeg. One pass, then list the
/// output directory. Capped at [maxFrames] total so a long clip doesn't
/// blow the analysis time budget; effective fps is reduced to hit that
/// cap on long videos.
class FrameExtractor {
  const FrameExtractor({
    this.capFps = 60,
    this.maxFrames = 60,
  });

  final int capFps;
  final int maxFrames;

  Future<List<ExtractedFrame>> extract({
    required String videoPath,
    required int sourceFps,
    required int durationMs,
    required String sessionId,
  }) async {
    if (durationMs <= 0) {
      throw FrameExtractorException('durationMs must be > 0');
    }
    var targetFps = sourceFps > capFps ? capFps : sourceFps;
    if (targetFps < 1) targetFps = 30;
    final projected = (durationMs / 1000.0) * targetFps;
    if (projected > maxFrames) {
      final capped = (maxFrames * 1000.0 / durationMs).floor();
      targetFps = capped < 1 ? 1 : capped;
    }
    final outDir = await _scratchDir(sessionId);
    final pattern = p.join(outDir.path, 'frame_%05d.jpg');
    final cmd = "-y -i '$videoPath' -vf fps=$targetFps -q:v 4 '$pattern'";
    final session = await FFmpegKit.execute(cmd);
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code)) {
      final logs = await session.getAllLogsAsString();
      throw FrameExtractorException(
        'ffmpeg failed (code=$code): ${logs ?? ''}',
      );
    }

    final files = outDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.jpg'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    if (files.isEmpty) {
      throw FrameExtractorException(
        'ffmpeg produced no frames for $videoPath',
      );
    }
    final frameIntervalMs = (1000 / targetFps).round();
    return [
      for (var i = 0; i < files.length; i++)
        ExtractedFrame(
          frameIndex: i,
          timestampMs: i * frameIntervalMs,
          filePath: files[i].path,
        ),
    ];
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
