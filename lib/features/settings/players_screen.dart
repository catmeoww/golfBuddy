import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../domain/models/player.dart';
import '../library/library_controller.dart';

class PlayersScreen extends ConsumerWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(allPlayersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Players')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: playersAsync.when(
        data: (players) {
          if (players.isEmpty) {
            return const Center(child: Text('No players yet'));
          }
          return ListView.separated(
            itemCount: players.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = players[i];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                  ),
                ),
                title: Text(p.name),
                subtitle: Text(p.type.name),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openEditor(context, ref, p),
                ),
                onTap: () => _openEditor(context, ref, p),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    Player? existing,
  ) async {
    final result = await showDialog<_PlayerDraft>(
      context: context,
      builder: (_) => _PlayerEditorDialog(initial: existing),
    );
    if (result == null) return;
    final repo = ref.read(playerRepositoryProvider);
    if (result.deleted) {
      if (existing != null) await repo.delete(existing.id);
      return;
    }
    await repo.upsert(
      Player(
        id: existing?.id ??
            'p-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
        name: result.name,
        type: result.type,
        avatarPath: existing?.avatarPath,
        createdAt: existing?.createdAt ?? DateTime.now(),
      ),
    );
  }
}

class _PlayerDraft {
  const _PlayerDraft({
    required this.name,
    required this.type,
    this.deleted = false,
  });

  final String name;
  final PlayerType type;
  final bool deleted;
}

class _PlayerEditorDialog extends StatefulWidget {
  const _PlayerEditorDialog({this.initial});

  final Player? initial;

  @override
  State<_PlayerEditorDialog> createState() => _PlayerEditorDialogState();
}

class _PlayerEditorDialogState extends State<_PlayerEditorDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late PlayerType _type = widget.initial?.type ?? PlayerType.student;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add player' : 'Edit player'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 16),
          const Text('Type'),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              for (final t in PlayerType.values)
                ChoiceChip(
                  label: Text(t.name),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                ),
            ],
          ),
        ],
      ),
      actions: [
        if (widget.initial != null)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(
              _PlayerDraft(name: '', type: PlayerType.student, deleted: true),
            ),
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop(
              _PlayerDraft(name: name, type: _type),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
