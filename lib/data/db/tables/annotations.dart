import 'package:drift/drift.dart';

import 'sessions.dart';

// Coach-persona revision: text annotations on a session, optionally
// anchored to a timestamp within the video. Audio-note annotations are
// deferred to v1.1.
@DataClassName('AnnotationRow')
class Annotations extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  IntColumn get timestampMs => integer().nullable()();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
