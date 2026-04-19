import 'package:drift/drift.dart';

import '../../domain/models/pose_frame.dart';
import '../db/database.dart';

class PoseFrameRepository {
  const PoseFrameRepository(this._db);

  final AppDatabase _db;

  Stream<List<PoseFrame>> watchForSession(String sessionId) {
    final query = _db.select(_db.poseFrames)
      ..where((f) => f.sessionId.equals(sessionId))
      ..orderBy([(f) => OrderingTerm(expression: f.frameIndex)]);
    return query.watch().map(
          (rows) => rows.map(_fromRow).toList(growable: false),
        );
  }

  Future<List<PoseFrame>> forSession(String sessionId) async {
    final rows = await (_db.select(_db.poseFrames)
          ..where((f) => f.sessionId.equals(sessionId))
          ..orderBy([(f) => OrderingTerm(expression: f.frameIndex)]))
        .get();
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<void> replaceForSession(
    String sessionId,
    List<PoseFrame> frames,
  ) async {
    await _db.transaction(() async {
      await (_db.delete(_db.poseFrames)
            ..where((f) => f.sessionId.equals(sessionId)))
          .go();
      for (final f in frames) {
        await _db.into(_db.poseFrames).insert(
              PoseFramesCompanion.insert(
                sessionId: sessionId,
                frameIndex: f.index,
                timestampMs: f.timestampMs,
                jointsJson: f.jointsToJson(),
                confidence: f.confidence,
              ),
            );
      }
    });
  }

  Future<void> delete(String sessionId) {
    return (_db.delete(_db.poseFrames)
          ..where((f) => f.sessionId.equals(sessionId)))
        .go();
  }

  PoseFrame _fromRow(PoseFrameRow row) => PoseFrame(
        index: row.frameIndex,
        timestampMs: row.timestampMs,
        joints: PoseFrame.jointsFromJson(row.jointsJson),
        confidence: row.confidence,
      );
}
