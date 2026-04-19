import 'package:drift/drift.dart';

import 'players.dart';

// LLD §5 — Sessions table. quality mirrors AnalysisQuality enum (ok|partial|failed).
@DataClassName('SessionRow')
class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get playerId => text().references(Players, #id)();
  TextColumn get club => text().nullable()();
  TextColumn get videoPath => text()();
  TextColumn get thumbPath => text()();
  DateTimeColumn get capturedAt => dateTime()();
  IntColumn get durationMs => integer()();
  IntColumn get fps => integer()();
  TextColumn get quality => text()();

  @override
  Set<Column> get primaryKey => {id};
}
