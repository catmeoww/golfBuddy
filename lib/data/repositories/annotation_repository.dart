import 'package:drift/drift.dart';

import '../../domain/models/annotation.dart';
import '../db/database.dart';

class AnnotationRepository {
  const AnnotationRepository(this._db);

  final AppDatabase _db;

  Stream<List<Annotation>> watchForSession(String sessionId) {
    final query = _db.select(_db.annotations)
      ..where((a) => a.sessionId.equals(sessionId))
      ..orderBy([
        (a) => OrderingTerm(expression: a.timestampMs),
        (a) => OrderingTerm(expression: a.createdAt),
      ]);
    return query.watch().map(
          (rows) => rows.map(_fromRow).toList(growable: false),
        );
  }

  Future<void> insert(Annotation annotation) {
    return _db.into(_db.annotations).insert(
          AnnotationsCompanion.insert(
            id: annotation.id,
            sessionId: annotation.sessionId,
            timestampMs: Value(annotation.timestampMs),
            body: annotation.text,
            createdAt: annotation.createdAt,
          ),
        );
  }

  Future<void> delete(String id) {
    return (_db.delete(_db.annotations)..where((a) => a.id.equals(id))).go();
  }

  Annotation _fromRow(AnnotationRow row) => Annotation(
        id: row.id,
        sessionId: row.sessionId,
        timestampMs: row.timestampMs,
        text: row.body,
        createdAt: row.createdAt,
      );
}
