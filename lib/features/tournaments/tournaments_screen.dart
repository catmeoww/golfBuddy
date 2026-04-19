import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../domain/models/tournament.dart';
import '../library/library_controller.dart';

class TournamentsScreen extends ConsumerWidget {
  const TournamentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(allTournamentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tournaments')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: tournamentsAsync.when(
        data: (tournaments) {
          if (tournaments.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No tournaments yet.\n\n'
                  'Add a tournament to tag sessions as before/during/after.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: tournaments.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final t = tournaments[i];
              return ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: Text(t.name),
                subtitle: Text(
                  '${_fmt(t.date)}${t.location == null ? '' : ' · ${t.location}'}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openEditor(context, ref, t),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  static String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    Tournament? existing,
  ) async {
    final result = await showDialog<_TournamentDraft>(
      context: context,
      builder: (_) => _TournamentEditorDialog(initial: existing),
    );
    if (result == null) return;
    final repo = ref.read(tournamentRepositoryProvider);
    if (result.deleted) {
      if (existing != null) await repo.delete(existing.id);
      return;
    }
    await repo.upsert(
      Tournament(
        id: existing?.id ??
            't-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
        name: result.name,
        date: result.date,
        location: result.location,
        notes: result.notes,
        createdAt: existing?.createdAt ?? DateTime.now(),
      ),
    );
  }
}

class _TournamentDraft {
  const _TournamentDraft({
    required this.name,
    required this.date,
    this.location,
    this.notes,
    this.deleted = false,
  });

  final String name;
  final DateTime date;
  final String? location;
  final String? notes;
  final bool deleted;
}

class _TournamentEditorDialog extends StatefulWidget {
  const _TournamentEditorDialog({this.initial});

  final Tournament? initial;

  @override
  State<_TournamentEditorDialog> createState() =>
      _TournamentEditorDialogState();
}

class _TournamentEditorDialogState
    extends State<_TournamentEditorDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _location = TextEditingController(
      text: widget.initial?.location ?? '');
  late final TextEditingController _notes =
      TextEditingController(text: widget.initial?.notes ?? '');
  late DateTime _date = widget.initial?.date ?? DateTime.now();

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add tournament' : 'Edit tournament'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Date: ${_date.year.toString().padLeft(4, '0')}-'
                    '${_date.month.toString().padLeft(2, '0')}-'
                    '${_date.day.toString().padLeft(2, '0')}',
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDate: _date,
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: const Text('Pick'),
                ),
              ],
            ),
            TextField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.initial != null)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(
              _TournamentDraft(name: '', date: DateTime.now(), deleted: true),
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
              _TournamentDraft(
                name: name,
                date: _date,
                location: _location.text.trim().isEmpty
                    ? null
                    : _location.text.trim(),
                notes:
                    _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
