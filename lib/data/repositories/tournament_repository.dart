import 'package:drift/drift.dart';

import '../../domain/models/tournament.dart';
import '../db/database.dart';

class TournamentRepository {
  const TournamentRepository(this._db);

  final AppDatabase _db;

  Stream<List<Tournament>> watchAll() {
    final query = _db.select(_db.tournaments)
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
      ]);
    return query.watch().map(
          (rows) => rows.map(_fromRow).toList(growable: false),
        );
  }

  Future<Tournament?> findById(String id) async {
    final row = await (_db.select(_db.tournaments)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<void> upsert(Tournament tournament) {
    return _db.into(_db.tournaments).insertOnConflictUpdate(
          TournamentsCompanion.insert(
            id: tournament.id,
            name: tournament.name,
            date: tournament.date,
            location: Value(tournament.location),
            notes: Value(tournament.notes),
            createdAt: tournament.createdAt,
          ),
        );
  }

  Future<void> delete(String id) {
    return (_db.delete(_db.tournaments)..where((t) => t.id.equals(id))).go();
  }

  Tournament _fromRow(TournamentRow row) => Tournament(
        id: row.id,
        name: row.name,
        date: row.date,
        location: row.location,
        notes: row.notes,
        createdAt: row.createdAt,
      );
}
