import 'package:drift/drift.dart';

import 'sessions.dart';

// FR-001 — coach-drawn shapes (circle / line) pinned to a video timestamp.
// Coords inside dataJson are normalized to 0..1 of the video frame so they
// survive any aspect-ratio scaling at paint time.
@DataClassName('MarkupRow')
class Markups extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  IntColumn get timestampMs => integer()();
  TextColumn get kind => text()();
  TextColumn get dataJson => text()();
  IntColumn get color => integer().withDefault(const Constant(0xFFFFC107))();
  RealColumn get strokeWidth => real().withDefault(const Constant(3.0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
