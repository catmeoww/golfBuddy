import 'package:drift/drift.dart';

import 'players.dart';
import 'tournaments.dart';

@DataClassName('SessionRow')
class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get playerId => text().references(Players, #id)();
  TextColumn get tournamentId =>
      text().nullable().references(Tournaments, #id)();
  TextColumn get tournamentRelation => text().nullable()();
  TextColumn get club => text().nullable()();
  TextColumn get videoPath => text()();
  TextColumn get thumbPath => text()();
  DateTimeColumn get capturedAt => dateTime()();
  IntColumn get durationMs => integer()();
  IntColumn get fps => integer()();
  TextColumn get quality =>
      text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
