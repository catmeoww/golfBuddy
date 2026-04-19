import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../library_controller.dart';

class PlayerChipRow extends ConsumerWidget {
  const PlayerChipRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(libraryFilterProvider);
    final playersAsync = ref.watch(allPlayersProvider);

    return SizedBox(
      height: 48,
      child: playersAsync.when(
        data: (players) {
          if (players.isEmpty) return const SizedBox.shrink();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: players.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              if (i == 0) {
                return FilterChip(
                  label: const Text('All'),
                  selected: filter.playerId == null,
                  onSelected: (_) => ref
                      .read(libraryFilterProvider.notifier)
                      .update((f) => f.copyWith(playerId: null)),
                );
              }
              final p = players[i - 1];
              final selected = filter.playerId == p.id;
              return FilterChip(
                label: Text(p.name),
                selected: selected,
                onSelected: (_) => ref
                    .read(libraryFilterProvider.notifier)
                    .update((f) => f.copyWith(playerId: selected ? null : p.id)),
              );
            },
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Players failed: $e'),
        ),
      ),
    );
  }
}
