import 'package:drift/drift.dart';

import 'sessions.dart';

// LLD §5 — PhaseMarkers table. phase value is one of address|top|impact|finish.
@DataClassName('PhaseMarkerRow')
class PhaseMarkers extends Table {
  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get phase => text()();
  IntColumn get frameIndex => integer()();
  IntColumn get timestampMs => integer()();
  RealColumn get confidence => real()();
  BoolColumn get manuallyAdjusted =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {sessionId, phase};
}
