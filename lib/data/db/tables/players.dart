import 'package:drift/drift.dart';

// Coach-persona revision: add player_type so the coach can distinguish
// the primary subject (child / student) from ad-hoc adult friends or
// themselves. Stored as a string for easy migration; see domain enum.
@DataClassName('PlayerRow')
class Players extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get avatarPath => text().nullable()();
  TextColumn get playerType =>
      text().withDefault(const Constant('student'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
