import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../library/library_controller.dart';

class TagResult {
  const TagResult({
    required this.playerId,
    this.club,
    this.tournamentId,
  });

  final String playerId;
  final String? club;
  final String? tournamentId;
}

class TagSheet extends ConsumerStatefulWidget {
  const TagSheet({required this.initialPlayerId, super.key});

  final String initialPlayerId;

  @override
  ConsumerState<TagSheet> createState() => _TagSheetState();
}

class _TagSheetState extends ConsumerState<TagSheet> {
  late String _playerId = widget.initialPlayerId;
  String? _club;
  String? _tournamentId;

  static const _clubs = ['Driver', 'Iron', 'Wedge', 'Putter'];

  @override
  Widget build(BuildContext context) {
    final players = ref.watch(allPlayersProvider).value ?? [];
    final tournaments = ref.watch(allTournamentsProvider).value ?? [];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tag swing', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Text('Player', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final p in players)
                    ChoiceChip(
                      label: Text(p.name),
                      selected: _playerId == p.id,
                      onSelected: (_) => setState(() => _playerId = p.id),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Club', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in _clubs)
                    ChoiceChip(
                      label: Text(c),
                      selected: _club == c,
                      onSelected: (_) => setState(
                        () => _club = _club == c ? null : c,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Tournament (optional)',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButton<String?>(
                value: _tournamentId,
                isExpanded: true,
                hint: const Text('None'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None'),
                  ),
                  for (final t in tournaments)
                    DropdownMenuItem<String?>(
                      value: t.id,
                      child: Text(t.name),
                    ),
                ],
                onChanged: (v) => setState(() => _tournamentId = v),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    TagResult(
                      playerId: _playerId,
                      club: _club,
                      tournamentId: _tournamentId,
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
