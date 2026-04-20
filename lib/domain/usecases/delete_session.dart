import 'package:drift/drift.dart';

import '../../data/db/database.dart';
import '../../data/files/video_storage.dart';

// Cascades: wipe annotations/metrics/phase_markers/pose_frames for the
// session, then the session row, then the video + thumbnail on disk.
// Wrapped in a transaction so partial failures don't leave orphans.
class DeleteSession {
  const DeleteSession({required this.db, required this.storage});

  final AppDatabase db;
  final VideoStorage storage;

  Future<void> call(String sessionId) async {
    await db.transaction(() async {
      await (db.delete(db.annotations)
            ..where((t) => t.sessionId.equals(sessionId)))
          .go();
      await (db.delete(db.metrics)
            ..where((t) => t.sessionId.equals(sessionId)))
          .go();
      await (db.delete(db.phaseMarkers)
            ..where((t) => t.sessionId.equals(sessionId)))
          .go();
      await (db.delete(db.poseFrames)
            ..where((t) => t.sessionId.equals(sessionId)))
          .go();
      await (db.delete(db.sessions)..where((t) => t.id.equals(sessionId)))
          .go();
    });
    await storage.delete(sessionId);
  }
}
