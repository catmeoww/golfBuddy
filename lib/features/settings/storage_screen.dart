import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../data/files/video_storage.dart';
import '../../domain/models/player.dart';
import '../../domain/models/session.dart';
import '../library/library_controller.dart';

final _totalBytesProvider = FutureProvider.autoDispose<int>((ref) {
  // Refresh when sessions change.
  ref.watch(librarySessionsProvider);
  return ref.watch(videoStorageProvider).totalBytes();
});

final _sessionSizeProvider =
    FutureProvider.autoDispose.family<int, String>((ref, sessionId) {
  return ref.watch(videoStorageProvider).sizeFor(sessionId);
});

class StorageScreen extends ConsumerWidget {
  const StorageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(librarySessionsProvider);
    final playersAsync = ref.watch(allPlayersProvider);
    final totalBytesAsync = ref.watch(_totalBytesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Storage')),
      body: sessionsAsync.when(
        data: (sessions) {
          final players = playersAsync.value ?? const <Player>[];
          final playerById = {for (final p in players) p.id: p};
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                totalBytesAsync: totalBytesAsync,
                sessionCount: sessions.length,
              ),
              const Divider(height: 1),
              Expanded(
                child: sessions.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        itemCount: sessions.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final s = sessions[i];
                          final player = playerById[s.playerId];
                          return _SessionRow(
                            session: s,
                            playerName: player?.name ?? 'Unknown',
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: const Text('Delete all my data'),
                    onPressed: () => _confirmWipeAll(context, ref),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Future<void> _confirmWipeAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
          'This wipes every session, video, annotation, tournament, and '
          'player from this device. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(wipeAllDataProvider).call();
    ref.invalidate(_totalBytesProvider);
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.totalBytesAsync,
    required this.sessionCount,
  });

  final AsyncValue<int> totalBytesAsync;
  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.storage, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                totalBytesAsync.when(
                  data: (bytes) => Text(
                    _formatBytes(bytes),
                    style: theme.textTheme.titleLarge,
                  ),
                  loading: () => Text('—', style: theme.textTheme.titleLarge),
                  error: (_, __) =>
                      Text('?', style: theme.textTheme.titleLarge),
                ),
                Text(
                  '$sessionCount session${sessionCount == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'No sessions on this device.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _SessionRow extends ConsumerWidget {
  const _SessionRow({required this.session, required this.playerName});

  final SwingSession session;
  final String playerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sizeAsync = ref.watch(_sessionSizeProvider(session.id));
    return ListTile(
      title: Text(playerName),
      subtitle: Text(
        _fmtDate(session.capturedAt) +
            (session.club != null ? ' · ${session.club}' : ''),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          sizeAsync.when(
            data: (bytes) => Text(_formatBytes(bytes)),
            loading: () => const Text('—'),
            error: (_, __) => const Text('?'),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this session?'),
        content: Text(
          'The video, notes, and metrics for $playerName on '
          '${_fmtDate(session.capturedAt)} will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(deleteSessionProvider).call(session.id);
    ref.invalidate(_totalBytesProvider);
  }

  static String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes / 1024;
  var i = 0;
  while (value >= 1024 && i < units.length - 1) {
    value /= 1024;
    i++;
  }
  final formatted = value >= 10 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  return '$formatted ${units[i]}';
}
