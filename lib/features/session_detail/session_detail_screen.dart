import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/di.dart';
import '../../domain/models/annotation.dart';
import '../../domain/models/metric.dart';
import '../../domain/models/session.dart';
import '../../domain/models/pose_frame.dart';
import '../../domain/models/swing_analysis.dart';
import '../analysis/analysis_controller.dart';
import '../analysis/metric_cards/head_stability_card.dart';
import '../analysis/metric_cards/hip_turn_card.dart';
import '../analysis/metric_cards/metric_card.dart';
import '../analysis/metric_cards/shoulder_turn_card.dart';
import '../analysis/metric_cards/tempo_card.dart';
import '../analysis/phase_scrubber.dart';
import '../analysis/skeleton_overlay.dart';
import '../../services/pose/metrics/head_stability.dart';
import '../../services/pose/metrics/rotation.dart';
import '../../services/pose/metrics/tempo.dart';
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
  int _positionMs = 0;

  @override
  void dispose() {
    _video?.removeListener(_onVideoTick);
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
    controller.addListener(_onVideoTick);
    setState(() {
      _video = controller;
      _videoReady = true;
    });
  }

  void _onVideoTick() {
    if (!mounted || _video == null) return;
    final ms = _video!.value.position.inMilliseconds;
    if (ms != _positionMs) {
      setState(() => _positionMs = ms);
    }
  }

  void _seek(int ms) {
    final v = _video;
    if (v == null || !v.value.isInitialized) return;
    v.seekTo(Duration(milliseconds: ms));
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionByIdProvider(widget.sessionId));
    final annotationsAsync =
        ref.watch(annotationsForSessionProvider(widget.sessionId));
    final metricsAsync =
        ref.watch(metricsForSessionProvider(widget.sessionId));
    final phasesAsync =
        ref.watch(phasesForSessionProvider(widget.sessionId));
    final poseFramesAsync =
        ref.watch(poseFramesForSessionProvider(widget.sessionId));
    final analyzeState =
        ref.watch(analyzeControllerProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session'),
        actions: [
          IconButton(
            tooltip: 'Compare',
            icon: const Icon(Icons.compare_arrows),
            onPressed: () =>
                context.go('/library/sessions/${widget.sessionId}/compare'),
          ),
        ],
      ),
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
          final annotations =
              annotationsAsync.value ?? const <Annotation>[];
          final phases = phasesAsync.value ?? const <PhaseMarker>[];
          final poseFrames = poseFramesAsync.value ?? const [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ContextBanner(
                playerName: playerAsync.value?.name ?? '—',
                capturedAt: session.capturedAt,
                club: session.club,
                tournamentName: tournamentAsync.value?.name,
                quality: session.quality,
              ),
              if (session.quality == AnalysisQuality.failed)
                _FailureBanner(
                  message: analyzeState.asError?.error.toString() ??
                      'Analysis failed. Video + notes still work; try again.',
                ),
              _VideoArea(
                controller: _videoReady ? _video : null,
                videoPath: session.videoPath,
                poseFrames: poseFrames,
                positionMs: _positionMs,
                showOverlay: session.quality == AnalysisQuality.ok ||
                    session.quality == AnalysisQuality.partial,
              ),
              const SizedBox(height: 4),
              PhaseScrubber(
                durationMs: session.durationMs,
                positionMs: _positionMs,
                phases: phases,
                annotations: annotations,
                onSeek: _seek,
              ),
              if (session.quality == AnalysisQuality.pending)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton.icon(
                    onPressed: analyzeState.isLoading
                        ? null
                        : () => ref
                            .read(analyzeControllerProvider(widget.sessionId)
                                .notifier)
                            .run(),
                    icon: analyzeState.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_fix_high),
                    label: Text(analyzeState.isLoading
                        ? 'Analyzing...'
                        : 'Analyze this swing'),
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                  children: [
                    if (metricsAsync.value != null &&
                        metricsAsync.value!.isNotEmpty)
                      _MetricsSection(metrics: metricsAsync.value!),
                    const SizedBox(height: 12),
                    _AnnotationsSection(
                      notes: annotations,
                      onTapNote: (note) {
                        final ts = note.timestampMs;
                        if (ts != null) _seek(ts);
                      },
                    ),
                  ],
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
    required this.quality,
    this.club,
    this.tournamentName,
  });

  final String playerName;
  final DateTime capturedAt;
  final String? club;
  final String? tournamentName;
  final AnalysisQuality quality;

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
                      (tournamentName != null ? ' · $tournamentName' : '') +
                      ' · ${quality.name}',
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

class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: 8),
            Expanded(child: Text('Analysis failed: $message')),
          ],
        ),
      ),
    );
  }
}

class _VideoArea extends StatelessWidget {
  const _VideoArea({
    required this.controller,
    required this.videoPath,
    required this.poseFrames,
    required this.positionMs,
    required this.showOverlay,
  });

  final VideoPlayerController? controller;
  final String videoPath;
  final List<PoseFrame> poseFrames;
  final int positionMs;
  final bool showOverlay;

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
          if (showOverlay && poseFrames.isNotEmpty)
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: SkeletonOverlay(
                    frames: poseFrames,
                    positionMs: positionMs,
                  ),
                ),
              ),
            ),
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

class _MetricsSection extends StatelessWidget {
  const _MetricsSection({required this.metrics});

  final List<Metric> metrics;

  @override
  Widget build(BuildContext context) {
    Metric? find(String name) {
      for (final m in metrics) {
        if (m.name == name) return m;
      }
      return null;
    }

    final tempo = find(TempoCalculator.metricName);
    final shoulder = find(RotationCalculator.shoulderMetric);
    final hip = find(RotationCalculator.hipMetric);
    final head = find(HeadStabilityCalculator.metricName);

    final cards = <Widget>[];
    if (tempo != null && tempo.confidence >= 0.5) {
      cards.add(TempoCard(metric: tempo));
    } else if (tempo != null) {
      cards.add(const MetricCard(
          title: 'Tempo ratio', valueText: 'Couldn\u2019t measure reliably'));
    }
    if (shoulder != null && shoulder.confidence >= 0.5) {
      cards.add(ShoulderTurnCard(metric: shoulder));
    }
    if (hip != null && hip.confidence >= 0.5) {
      cards.add(HipTurnCard(metric: hip));
    }
    if (head != null && head.confidence >= 0.5) {
      cards.add(HeadStabilityCard(metric: head));
    }
    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text('Metrics',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.6,
          children: cards,
        ),
      ],
    );
  }
}

class _AnnotationsSection extends StatelessWidget {
  const _AnnotationsSection({
    required this.notes,
    required this.onTapNote,
  });

  final List<Annotation> notes;
  final ValueChanged<Annotation> onTapNote;

  @override
  Widget build(BuildContext context) {
    final sessionNote = notes.where((n) => n.timestampMs == null).toList();
    final anchored = notes.where((n) => n.timestampMs != null).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
