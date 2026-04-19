import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../core/di.dart';
import '../../domain/models/annotation.dart';
import 'add_annotation_sheet.dart';
import 'session_detail_controller.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState
    extends ConsumerState<SessionDetailScreen> {
  VideoPlayerController? _video;
  bool _videoReady = false;

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  Future<void> _initVideoIfNeeded(String path) async {
    if (_video != null) return;
    final file = File(path);
    if (!await file.exists()) return;
    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    if (!mounted) return;
    setState(() {
      _video = controller;
      _videoReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionByIdProvider(widget.sessionId));
    final annotationsAsync =
        ref.watch(annotationsForSessionProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Session')),
      body: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Session not found'));
          }
          _initVideoIfNeeded(session.videoPath);
          final playerAsync =
              ref.watch(playerByIdProvider(session.playerId));
          final tournamentAsync = session.tournamentId == null
              ? const AsyncValue.data(null)
              : ref.watch(tournamentByIdProvider(session.tournamentId!));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ContextBanner(
                playerName: playerAsync.value?.name ?? '—',
                capturedAt: session.capturedAt,
                club: session.club,
                tournamentName: tournamentAsync.value?.name,
              ),
              _VideoArea(
                controller: _videoReady ? _video : null,
                videoPath: session.videoPath,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: annotationsAsync.when(
                  data: (notes) => _AnnotationsPanel(
                    notes: notes,
                    onAdd: () => _showAddAnnotation(null),
                    onTapNote: (note) {
                      final ts = note.timestampMs;
                      if (ts != null && _video != null) {
                        _video!.seekTo(Duration(milliseconds: ts));
                      }
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final pos = _video?.value.position.inMilliseconds;
          _showAddAnnotation(pos);
        },
        icon: const Icon(Icons.bookmark_add_outlined),
        label: const Text('Note at now'),
      ),
    );
  }

  Future<void> _showAddAnnotation(int? timestampMs) async {
    final result = await showModalBottomSheet<AddAnnotationResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddAnnotationSheet(initialTimestampMs: timestampMs),
    );
    if (result == null) return;
    final repo = ref.read(annotationRepositoryProvider);
    await repo.insert(
      Annotation(
        id: 'ann-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
        sessionId: widget.sessionId,
        timestampMs: result.timestampMs,
        text: result.text,
        createdAt: DateTime.now(),
      ),
    );
  }
}

class _ContextBanner extends StatelessWidget {
  const _ContextBanner({
    required this.playerName,
    required this.capturedAt,
    this.club,
    this.tournamentName,
  });

  final String playerName;
  final DateTime capturedAt;
  final String? club;
  final String? tournamentName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          CircleAvatar(
            child: Text(
              playerName.isNotEmpty ? playerName[0].toUpperCase() : '?',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(playerName, style: theme.textTheme.titleMedium),
                Text(
                  _fmt(capturedAt) +
                      (club != null ? ' · $club' : '') +
                      (tournamentName != null ? ' · $tournamentName' : ''),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

class _VideoArea extends StatelessWidget {
  const _VideoArea({required this.controller, required this.videoPath});

  final VideoPlayerController? controller;
  final String videoPath;

  @override
  Widget build(BuildContext context) {
    if (!File(videoPath).existsSync()) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.black12,
          child: Center(child: Text('Video file missing')),
        ),
      );
    }
    final c = controller;
    if (c == null || !c.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return AspectRatio(
      aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
      child: Stack(
        children: [
          VideoPlayer(c),
          Positioned(
            right: 8,
            bottom: 8,
            child: FloatingActionButton.small(
              heroTag: 'playToggle',
              onPressed: () {
                c.value.isPlaying ? c.pause() : c.play();
              },
              child: Icon(
                c.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 64,
            bottom: 8,
            child: VideoProgressIndicator(c, allowScrubbing: true),
          ),
        ],
      ),
    );
  }
}

class _AnnotationsPanel extends StatelessWidget {
  const _AnnotationsPanel({
    required this.notes,
    required this.onAdd,
    required this.onTapNote,
  });

  final List<Annotation> notes;
  final VoidCallback onAdd;
  final ValueChanged<Annotation> onTapNote;

  @override
  Widget build(BuildContext context) {
    final sessionNote = notes.where((n) => n.timestampMs == null).toList();
    final anchored = notes.where((n) => n.timestampMs != null).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        Text('Notes', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (sessionNote.isEmpty && anchored.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No notes yet. Tap "Note at now" while playing to pin a note to a moment.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        for (final n in sessionNote)
          Card(child: ListTile(title: Text(n.text))),
        if (anchored.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'At timestamps',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          for (final n in anchored)
            Card(
              child: ListTile(
                leading: const Icon(Icons.bookmark),
                title: Text(n.text),
                subtitle: Text(_formatMs(n.timestampMs!)),
                onTap: () => onTapNote(n),
              ),
            ),
        ],
      ],
    );
  }

  static String _formatMs(int ms) {
    final s = (ms / 1000).toStringAsFixed(2);
    return '${s}s';
  }
}
