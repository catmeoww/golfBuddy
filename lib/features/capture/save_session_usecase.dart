import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/di.dart';
import '../../data/files/video_storage.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/models/session.dart';
import '../../services/video/thumbnail_generator.dart';

class SaveSessionInput {
  const SaveSessionInput({
    required this.tempVideo,
    required this.playerId,
    required this.capturedAt,
    required this.durationMs,
    required this.fps,
    this.club,
    this.tournamentId,
  });

  final File tempVideo;
  final String playerId;
  final DateTime capturedAt;
  final int durationMs;
  final int fps;
  final String? club;
  final String? tournamentId;
}

class SaveSession {
  const SaveSession(
    this._storage,
    this._sessions, [
    this._thumbs = const ThumbnailGenerator(),
  ]);

  final VideoStorage _storage;
  final SessionRepository _sessions;
  final ThumbnailGenerator _thumbs;

  Future<String> call(SaveSessionInput input) async {
    final sessionId =
        'sess-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    final targetPath = await _storage.resolveVideoPath(sessionId);
    final thumbPath = await _storage.resolveThumbPath(sessionId);
    final target = File(targetPath);
    await target.parent.create(recursive: true);
    await input.tempVideo.rename(targetPath).catchError((_) async {
      // Fallback when temp and target live on different filesystems.
      final bytes = await input.tempVideo.readAsBytes();
      await target.writeAsBytes(bytes, flush: true);
      await input.tempVideo.delete();
      return target;
    });

    await _thumbs.generate(videoPath: targetPath, outputPath: thumbPath);

    await _sessions.insert(
      SwingSession(
        id: sessionId,
        playerId: input.playerId,
        tournamentId: input.tournamentId,
        club: input.club,
        videoPath: targetPath,
        thumbPath: thumbPath,
        capturedAt: input.capturedAt,
        durationMs: input.durationMs,
        fps: input.fps,
        quality: AnalysisQuality.pending,
      ),
    );

    return sessionId;
  }

  String sessionIdFromPath(String path) =>
      p.basenameWithoutExtension(path);
}

final saveSessionProvider = Provider<SaveSession>((ref) {
  return SaveSession(
    ref.watch(videoStorageProvider),
    ref.watch(sessionRepositoryProvider),
  );
});
