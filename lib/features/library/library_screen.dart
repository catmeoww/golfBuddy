import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/player.dart';
import '../../domain/models/tournament.dart';
import '../../services/pose/metrics/tempo.dart';
import 'library_controller.dart';
import 'widgets/player_chip_row.dart';
import 'widgets/session_card.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(librarySessionsProvider);
    final playersAsync = ref.watch(allPlayersProvider);
    final tournamentsAsync = ref.watch(allTournamentsProvider);
    final filter = ref.watch(libraryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.trending_up),
            tooltip: 'Trend',
            onPressed: () => _openTrend(context, ref, filter.playerId),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: 'Tournaments',
            onPressed: () => context.go('/library/tournaments'),
          ),
        ],
      ),
      body: Column(
        children: [
          const PlayerChipRow(),
          const SizedBox(height: 4),
          Expanded(
            child: sessionsAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const _EmptyLibrary();
                }
                final players = playersAsync.value ?? const <Player>[];
                final tournaments =
                    tournamentsAsync.value ?? const <Tournament>[];
                final playerById = {for (final p in players) p.id: p};
                final tournamentById = {
                  for (final t in tournaments) t.id: t,
                };

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: sessions.length,
                  itemBuilder: (context, i) {
                    final s = sessions[i];
                    final player = playerById[s.playerId];
                    final tournament = s.tournamentId == null
                        ? null
                        : tournamentById[s.tournamentId];
                    return SessionCard(
                      session: s,
                      playerName: player?.name ?? 'Unknown',
                      tournamentName: tournament?.name,
                      onTap: () => context.go('/library/sessions/${s.id}'),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openTrend(
    BuildContext context,
    WidgetRef ref,
    String? filteredPlayerId,
  ) async {
    String? playerId = filteredPlayerId;
    if (playerId == null) {
      final players = ref.read(allPlayersProvider).value ?? const <Player>[];
      if (players.isEmpty) return;
      playerId = await showDialog<String>(
        context: context,
        builder: (_) => SimpleDialog(
          title: const Text('Pick a player'),
          children: [
            for (final p in players)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(p.id),
                child: Text(p.name),
              ),
          ],
        ),
      );
      if (playerId == null) return;
    }
    if (!context.mounted) return;
    context.go(
        '/library/trend?playerId=$playerId&metricName=${TempoCalculator.metricName}');
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.golf_course, size: 64),
            const SizedBox(height: 16),
            Text(
              'No swings yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Record your first swing in the Capture tab.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
