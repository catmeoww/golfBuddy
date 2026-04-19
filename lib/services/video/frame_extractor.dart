import 'dart:io';

import 'package:ffmpeg_kit_flutter_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min/return_code.dart';
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

/// LLD §4 — extract frames from a recorded swing video using ffmpeg,
/// capped at [capFps] (default 60) to keep pose inference in budget.
class FrameExtractor {
  const FrameExtractor({this.capFps = 60});

  final int capFps;

  Future<List<ExtractedFrame>> extract({
    required String videoPath,
    required int sourceFps,
    required String sessionId,
  }) async {
    final targetFps = sourceFps > capFps ? capFps : sourceFps;
    final outDir = await _scratchDir(sessionId);
    final pattern = p.join(outDir.path, 'frame_%05d.jpg');

    final cmd =
        "-y -i '$videoPath' -vf fps=$targetFps '$pattern'";
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
