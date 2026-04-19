import 'package:drift/drift.dart';

import 'sessions.dart';

// LLD §5 — Metrics table. (sessionId, name) composite PK.
@DataClassName('MetricRow')
class Metrics extends Table {
  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get name => text()();
  RealColumn get value => real()();
  RealColumn get confidence => real()();
  TextColumn get bandLabel => text().nullable()();

  @override
  Set<Column> get primaryKey => {sessionId, name};
}
