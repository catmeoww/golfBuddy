import 'package:drift/drift.dart';

import '../../domain/models/markup.dart';
import '../db/database.dart';

class MarkupRepository {
  const MarkupRepository(this._db);

  final AppDatabase _db;

  Stream<List<Markup>> watchForSession(String sessionId) {
    final query = _db.select(_db.markups)
      ..where((m) => m.sessionId.equals(sessionId))
      ..orderBy([
        (m) => OrderingTerm(expression: m.timestampMs),
        (m) => OrderingTerm(expression: m.createdAt),
      ]);
    return query.watch().map(
          (rows) => rows.map(_fromRow).toList(growable: false),
        );
  }

  Future<void> insert(Markup m) {
    return _db.into(_db.markups).insert(
          MarkupsCompanion.insert(
            id: m.id,
            sessionId: m.sessionId,
            timestampMs: m.timestampMs,
            kind: m.kind.name,
            dataJson: m.dataToJson(),
            color: Value(m.color),
            strokeWidth: Value(m.strokeWidth),
            createdAt: m.createdAt,
          ),
        );
  }

  Future<void> delete(String id) {
    return (_db.delete(_db.markups)..where((m) => m.id.equals(id))).go();
  }

  Future<void> deleteAllForSession(String sessionId) {
    return (_db.delete(_db.markups)
          ..where((m) => m.sessionId.equals(sessionId)))
        .go();
  }

  Markup _fromRow(MarkupRow row) => Markup.fromRow(
        id: row.id,
        sessionId: row.sessionId,
        timestampMs: row.timestampMs,
        kind: row.kind,
        dataJson: row.dataJson,
        color: row.color,
        strokeWidth: row.strokeWidth,
        createdAt: row.createdAt,
      );
}
