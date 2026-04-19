import 'package:drift/drift.dart';

// Coach-persona revision: tournament events are first-class. Coach plans
// sessions against Ethan's last tournament performance, so sessions link
// to a tournament for before/after analysis.
@DataClassName('TournamentRow')
class Tournaments extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get location => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
