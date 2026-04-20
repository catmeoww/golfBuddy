import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di.dart';
import '../../domain/models/player.dart';
import '../library/library_controller.dart';
import 'capture_controller.dart';
import 'save_session_usecase.dart';
import 'tag_sheet.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  String? _selectedPlayerId;
  DateTime? _recordingStartedAt;
  int _countdownSeconds = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(captureControllerProvider.notifier).initCamera();
    });
  }

  @override
  Widget build(BuildContext context) {
    final capture = ref.watch(captureControllerProvider);
    final controller =
        ref.read(captureControllerProvider.notifier).cameraController;
    final playersAsync = ref.watch(allPlayersProvider);

    // Auto-select the first player if nothing's chosen yet.
    playersAsync.whenData((players) {
      if (_selectedPlayerId == null && players.isNotEmpty) {
        _selectedPlayerId = players.first.id;
      }
    });

    final notifier = ref.read(captureControllerProvider.notifier);
    final canFlip = notifier.hasMultipleLenses;
    final flipDisabled = capture.stage == CaptureStage.recording ||
        capture.stage == CaptureStage.countdown;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture'),
        actions: [
          IconButton(
            tooltip: capture.lensDirection == CameraLensDirection.front
                ? 'Switch to back camera'
                : 'Switch to front camera',
            icon: Icon(
              capture.lensDirection == CameraLensDirection.front
                  ? Icons.camera_rear_outlined
                  : Icons.camera_front_outlined,
            ),
            onPressed: (!canFlip || flipDisabled) ? null : notifier.flipCamera,
          ),
          DropdownButton<int>(
            value: _countdownSeconds,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 0, child: Text('Off')),
              DropdownMenuItem(value: 3, child: Text('3s')),
              DropdownMenuItem(value: 5, child: Text('5s')),
              DropdownMenuItem(value: 10, child: Text('10s')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _countdownSeconds = v);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _PlayerChipSelector(
              selectedId: _selectedPlayerId,
              onSelect: (id) => setState(() => _selectedPlayerId = id),
            ),
            const _AngleHint(),
            Expanded(
              child: _Preview(
                capture: capture,
                controller: controller,
              ),
            ),
            _ControlBar(
              capture: capture,
              onStart: _selectedPlayerId == null
                  ? null
                  : () async {
                      _recordingStartedAt = DateTime.now();
                      await ref
                          .read(captureControllerProvider.notifier)
                          .startCountdown(_countdownSeconds);
                    },
              onStop: () async {
                final file = await ref
                    .read(captureControllerProvider.notifier)
                    .stopRecording();
                if (file == null || _selectedPlayerId == null) return;
                if (!mounted) return;
                final tag = await showModalBottomSheet<TagResult>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => TagSheet(
                    initialPlayerId: _selectedPlayerId!,
                  ),
                );
                if (tag == null) return;
                final durationMs = _recordingStartedAt == null
                    ? 0
                    : DateTime.now()
                        .difference(_recordingStartedAt!)
                        .inMilliseconds;
                final sessionId =
                    await ref.read(saveSessionProvider).call(
                          SaveSessionInput(
                            tempVideo: file,
                            playerId: tag.playerId,
                            capturedAt: DateTime.now(),
                            durationMs: durationMs,
                            fps: 30,
                            club: tag.club,
                            tournamentId: tag.tournamentId,
                          ),
                        );
                if (!mounted) return;
                ref.read(captureControllerProvider.notifier).reset();
                context.go('/library/sessions/$sessionId');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.capture, required this.controller});

  final CaptureState capture;
  final CameraController? controller;

  @override
  Widget build(BuildContext context) {
    if (capture.stage == CaptureStage.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Camera error: ${capture.error ?? 'unknown'}'),
        ),
      );
    }
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        CameraPreview(controller!),
        if (capture.stage == CaptureStage.countdown)
          Text(
            '${capture.countdownRemaining}',
            style: const TextStyle(
              fontSize: 96,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (capture.stage == CaptureStage.recording)
          const Positioned(
            top: 12,
            child: _RecordingPill(),
          ),
      ],
    );
  }
}

class _RecordingPill extends StatelessWidget {
  const _RecordingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fiber_manual_record, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text('REC', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.capture,
    required this.onStart,
    required this.onStop,
  });

  final CaptureState capture;
  final VoidCallback? onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final isRecording = capture.stage == CaptureStage.recording ||
        capture.stage == CaptureStage.countdown;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: FloatingActionButton(
              backgroundColor: isRecording ? Colors.red : Colors.white,
              foregroundColor: isRecording ? Colors.white : Colors.red,
              onPressed: onStart == null
                  ? null
                  : (isRecording ? onStop : onStart),
              child: Icon(
                isRecording ? Icons.stop : Icons.fiber_manual_record,
                size: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AngleHint extends StatelessWidget {
  const _AngleHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'For accurate metrics, film down-the-line or face-on. '
              'Behind-the-golfer loses most of the swing motion.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerChipSelector extends ConsumerWidget {
  const _PlayerChipSelector({
    required this.selectedId,
    required this.onSelect,
  });

  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(allPlayersProvider);
    return SizedBox(
      height: 52,
      child: playersAsync.when(
        data: (players) {
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: players.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              if (i == players.length) {
                return ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  onPressed: () => _promptAddPlayer(context, ref),
                );
              }
              final p = players[i];
              return ChoiceChip(
                label: Text(p.name),
                avatar: CircleAvatar(
                  child: Text(
                    p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                  ),
                ),
                selected: selectedId == p.id,
                onSelected: (_) => onSelect(p.id),
              );
            },
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Future<void> _promptAddPlayer(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add player'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    final id = 'p-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    await ref.read(playerRepositoryProvider).upsert(
          Player(
            id: id,
            name: name,
            type: PlayerType.friend,
            createdAt: DateTime.now(),
          ),
        );
    onSelect(id);
  }
}
