import 'package:drift/drift.dart';

import 'sessions.dart';

// LLD §4 — cached pose results per frame. Joints stored as JSON blob.
@DataClassName('PoseFrameRow')
class PoseFrames extends Table {
  TextColumn get sessionId => text().references(Sessions, #id)();
  IntColumn get frameIndex => integer()();
  IntColumn get timestampMs => integer()();
  TextColumn get jointsJson => text()();
  RealColumn get confidence => real()();

  @override
  Set<Column> get primaryKey => {sessionId, frameIndex};
}
