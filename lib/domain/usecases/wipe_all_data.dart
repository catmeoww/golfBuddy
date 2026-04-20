import '../../data/db/database.dart';
import '../../data/files/video_storage.dart';

// Nukes every user row + every on-disk video. For Settings -> Delete
// all my data. Does NOT re-seed players; the bootstrap provider does
// that on next launch.
class WipeAllData {
  const WipeAllData({required this.db, required this.storage});

  final AppDatabase db;
  final VideoStorage storage;

  Future<void> call() async {
    await db.transaction(() async {
      await db.delete(db.annotations).go();
      await db.delete(db.metrics).go();
      await db.delete(db.phaseMarkers).go();
      await db.delete(db.poseFrames).go();
      await db.delete(db.sessions).go();
      await db.delete(db.tournaments).go();
      await db.delete(db.players).go();
    });
    await storage.clearAll();
  }
}
