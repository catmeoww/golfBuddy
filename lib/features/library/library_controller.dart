import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/models/player.dart';
import '../../domain/models/session.dart';
import '../../domain/models/tournament.dart';

class LibraryFilter {
  const LibraryFilter({this.playerId, this.tournamentId, this.club});

  final String? playerId;
  final String? tournamentId;
  final String? club;

  LibraryFilter copyWith({
    Object? playerId = _sentinel,
    Object? tournamentId = _sentinel,
    Object? club = _sentinel,
  }) {
    return LibraryFilter(
      playerId: identical(playerId, _sentinel)
          ? this.playerId
          : playerId as String?,
      tournamentId: identical(tournamentId, _sentinel)
          ? this.tournamentId
          : tournamentId as String?,
      club: identical(club, _sentinel) ? this.club : club as String?,
    );
  }

  static const Object _sentinel = Object();
}

final libraryFilterProvider =
    StateProvider<LibraryFilter>((ref) => const LibraryFilter());

final librarySessionsProvider = StreamProvider<List<SwingSession>>((ref) {
  final filter = ref.watch(libraryFilterProvider);
  final repo = ref.watch(sessionRepositoryProvider);
  return repo.watch(
    SessionFilter(
      playerId: filter.playerId,
      tournamentId: filter.tournamentId,
      club: filter.club,
    ),
  );
});

final allPlayersProvider = StreamProvider<List<Player>>((ref) {
  return ref.watch(playerRepositoryProvider).watchAll();
});

final allTournamentsProvider = StreamProvider<List<Tournament>>((ref) {
  return ref.watch(tournamentRepositoryProvider).watchAll();
});
