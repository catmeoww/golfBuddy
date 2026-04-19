import 'package:drift/drift.dart';

import '../../domain/models/player.dart';
import '../db/database.dart';

class PlayerRepository {
  const PlayerRepository(this._db);

  final AppDatabase _db;

  Stream<List<Player>> watchAll() {
    final query = _db.select(_db.players)
      ..orderBy([(p) => OrderingTerm(expression: p.createdAt)]);
    return query.watch().map(
          (rows) => rows.map(_fromRow).toList(growable: false),
        );
  }

  Future<Player?> findById(String id) async {
    final row = await (_db.select(_db.players)
          ..where((p) => p.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<void> upsert(Player player) {
    return _db.into(_db.players).insertOnConflictUpdate(
          PlayersCompanion.insert(
            id: player.id,
            name: player.name,
            playerType: Value(player.type.name),
            avatarPath: Value(player.avatarPath),
            createdAt: player.createdAt,
          ),
        );
  }

  Future<void> delete(String id) {
    return (_db.delete(_db.players)..where((p) => p.id.equals(id))).go();
  }

  Player _fromRow(PlayerRow row) => Player(
        id: row.id,
        name: row.name,
        type: PlayerType.parse(row.playerType),
        avatarPath: row.avatarPath,
        createdAt: row.createdAt,
      );
}
