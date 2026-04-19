import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/player_repository.dart';
import '../domain/models/player.dart';
import 'di.dart';

// PRD F2.1 — seed a default subject on first run so the coach never has to
// configure a player before capturing the first clip. We seed "Ethan" to
// match P01's household; renamed in Settings for other households.
class AppBootstrap {
  const AppBootstrap(this._players);

  final PlayerRepository _players;

  Future<void> run() async {
    final existing = await _players
        .watchAll()
        .first
        .catchError((_) => <Player>[]);
    if (existing.isNotEmpty) return;
    await _players.upsert(
      Player(
        id: 'seed-ethan',
        name: 'Ethan',
        type: PlayerType.child,
        createdAt: DateTime.now(),
      ),
    );
  }
}

final bootstrapProvider = FutureProvider<void>((ref) async {
  final players = ref.read(playerRepositoryProvider);
  await AppBootstrap(players).run();
});
