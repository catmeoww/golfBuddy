import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/di.dart';
import '../../domain/models/annotation.dart';
import '../../domain/models/markup.dart';
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
import 'markup_overlay.dart';
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
  double _playbackSpeed = 1.0;

  // FR-001 — Draw mode state.
  bool _drawMode = false;
  MarkupKind _activeTool = MarkupKind.circle;
  // FR-007 — active color now mutable; resets to yellow each screen entry.
  Color _drawColor = const Color(0xFFFFC107);
  static const double _drawStroke = 3.0;

  static const _colorPresets = <Color>[
    Color(0xFFFFC107), // yellow
    Color(0xFF2BB673), // green
    Color(0xFFE53935), // red
    Color(0xFF1E88E5), // blue
    Color(0xFFFFFFFF), // white
  ];

  static const _speedCycle = [1.0, 0.5, 0.25];

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
    await controller.setLooping(true);
    await controller.setPlaybackSpeed(_playbackSpeed);
    controller.addListener(_onVideoTick);
    setState(() {
      _video = controller;
      _videoReady = true;
    });
  }

  Future<void> _togglePlay() async {
    final c = _video;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      if (c.value.position >= c.value.duration) {
        await c.seekTo(Duration.zero);
      }
      await c.play();
    }
  }

  Future<void> _restart() async {
    final c = _video;
    if (c == null || !c.value.isInitialized) return;
    await c.seekTo(Duration.zero);
    await c.play();
  }

  Future<void> _cycleSpeed() async {
    final c = _video;
    if (c == null || !c.value.isInitialized) return;
    final i = _speedCycle.indexOf(_playbackSpeed);
    final next = _speedCycle[(i + 1) % _speedCycle.length];
    await c.setPlaybackSpeed(next);
    setState(() => _playbackSpeed = next);
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

  void _toggleDrawMode() {
    setState(() => _drawMode = !_drawMode);
    if (_drawMode) {
      // Pause so the coach is annotating a static frame.
      _video?.pause();
    }
  }

  Future<void> _confirmDeleteMarkup(Markup m) async {
    if (_drawMode) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Delete drawing?'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(sheetCtx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(sheetCtx).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await ref.read(markupRepositoryProvider).delete(m.id);
    }
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
    final markupsAsync =
        ref.watch(markupsForSessionProvider(widget.sessionId));
    final analyzeState =
        ref.watch(analyzeControllerProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session'),
        actions: [
          IconButton(
            tooltip: _drawMode ? 'Exit draw mode' : 'Draw on video',
            icon: Icon(_drawMode ? Icons.edit_off : Icons.edit_outlined),
            onPressed: _toggleDrawMode,
          ),
          IconButton(
            tooltip: 'Compare',
            icon: const Icon(Icons.compare_arrows),
            onPressed: () =>
                context.push('/library/sessions/${widget.sessionId}/compare'),
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
          final markups = markupsAsync.value ?? const <Markup>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 96),
            child: Column(
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
                if (_drawMode)
                  DrawToolbar(
                    activeTool: _activeTool,
                    onPickTool: (k) => setState(() => _activeTool = k),
                    activeColor: _drawColor,
                    colorPresets: _colorPresets,
                    onPickColor: (c) => setState(() => _drawColor = c),
                    onDone: _toggleDrawMode,
                  ),
                _VideoArea(
                  controller: _videoReady ? _video : null,
                  videoPath: session.videoPath,
                  poseFrames: poseFrames,
                  positionMs: _positionMs,
                  showOverlay: session.quality == AnalysisQuality.ok ||
                      session.quality == AnalysisQuality.partial,
                  playbackSpeed: _playbackSpeed,
                  onPlayPause: _togglePlay,
                  onRestart: _restart,
                  onCycleSpeed: _cycleSpeed,
                  markups: markups,
                  drawMode: _drawMode,
                  activeTool: _activeTool,
                  drawColor: _drawColor,
                  drawStroke: _drawStroke,
                  sessionId: widget.sessionId,
                  onMarkupDrawn: (m) async {
                    await ref.read(markupRepositoryProvider).insert(m);
                  },
                  onMarkupTapped: _confirmDeleteMarkup,
                ),
                const SizedBox(height: 4),
                PhaseScrubber(
                  durationMs: session.durationMs,
                  positionMs: _positionMs,
                  phases: phases,
                  annotations: annotations,
                  onSeek: _seek,
                ),
                if (session.quality != AnalysisQuality.ok)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: FilledButton.icon(
                      onPressed: analyzeState.isLoading
                          ? null
                          : () async {
                              await ref
                                  .read(analyzeControllerProvider(
                                          widget.sessionId)
                                      .notifier)
                                  .run();
                              ref.invalidate(
                                  sessionByIdProvider(widget.sessionId));
                            },
                      icon: analyzeState.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(session.quality == AnalysisQuality.failed
                              ? Icons.refresh
                              : Icons.auto_fix_high),
                      label: Text(analyzeState.isLoading
                          ? 'Analyzing...'
                          : session.quality == AnalysisQuality.failed
                              ? 'Retry analysis'
                              : session.quality == AnalysisQuality.partial
                                  ? 'Re-run analysis'
                                  : 'Analyze this swing'),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
            ),
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
    required this.playbackSpeed,
    required this.onPlayPause,
    required this.onRestart,
    required this.onCycleSpeed,
    required this.markups,
    required this.drawMode,
    required this.activeTool,
    required this.drawColor,
    required this.drawStroke,
    required this.sessionId,
    required this.onMarkupDrawn,
    required this.onMarkupTapped,
  });

  final VideoPlayerController? controller;
  final String videoPath;
  final List<PoseFrame> poseFrames;
  final int positionMs;
  final bool showOverlay;
  final double playbackSpeed;
  final VoidCallback onPlayPause;
  final VoidCallback onRestart;
  final VoidCallback onCycleSpeed;
  final List<Markup> markups;
  final bool drawMode;
  final MarkupKind activeTool;
  final Color drawColor;
  final double drawStroke;
  final String sessionId;
  final void Function(Markup) onMarkupDrawn;
  final void Function(Markup) onMarkupTapped;

  @override
  Widget build(BuildContext context) {
    // Cap video area to 45% of screen height so portrait (9:16) clips
    // don't push the Analyze button and metrics off the bottom.
    final maxH = MediaQuery.sizeOf(context).height * 0.45;
    if (!File(videoPath).existsSync()) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: const AspectRatio(
          aspectRatio: 16 / 9,
          child: ColoredBox(
            color: Colors.black12,
            child: Center(child: Text('Video file missing')),
          ),
        ),
      );
    }
    final c = controller;
    if (c == null || !c.value.isInitialized) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: const AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final ratio = c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: AspectRatio(
      aspectRatio: ratio,
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
          Positioned.fill(
            child: MarkupOverlay(
              markups: markups,
              positionMs: positionMs,
              drawMode: drawMode,
              activeTool: activeTool,
              color: drawColor,
              strokeWidth: drawStroke,
              sessionId: sessionId,
              onDrawn: onMarkupDrawn,
              onTapMarkup: onMarkupTapped,
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VideoProgressIndicator(c, allowScrubbing: true),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'restart',
                      backgroundColor:
                          Colors.black.withValues(alpha: 0.5),
                      foregroundColor: Colors.white,
                      onPressed: onRestart,
                      child: const Icon(Icons.replay),
                    ),
                    FloatingActionButton.small(
                      heroTag: 'playToggle',
                      onPressed: onPlayPause,
                      child: Icon(
                        c.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                    ),
                    FloatingActionButton.small(
                      heroTag: 'speed',
                      backgroundColor:
                          Colors.black.withValues(alpha: 0.5),
                      foregroundColor: Colors.white,
                      onPressed: onCycleSpeed,
                      child: Text(
                        playbackSpeed == 1.0
                            ? '1x'
                            : '${playbackSpeed}x',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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

    const lowConfLabel = 'Couldn\u2019t measure reliably';
    final cards = <Widget>[
      if (tempo != null && tempo.confidence >= 0.5)
        TempoCard(metric: tempo)
      else
        const MetricCard(title: 'Tempo ratio', valueText: lowConfLabel),
      if (shoulder != null && shoulder.confidence >= 0.5)
        ShoulderTurnCard(metric: shoulder)
      else
        const MetricCard(title: 'Shoulder turn', valueText: lowConfLabel),
      if (hip != null && hip.confidence >= 0.5)
        HipTurnCard(metric: hip)
      else
        const MetricCard(title: 'Hip turn', valueText: lowConfLabel),
      if (head != null && head.confidence >= 0.5)
        HeadStabilityCard(metric: head)
      else
        const MetricCard(title: 'Head stability', valueText: lowConfLabel),
    ];
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

class DrawToolbar extends StatelessWidget {
  const DrawToolbar({
    required this.activeTool,
    required this.onPickTool,
    required this.activeColor,
    required this.colorPresets,
    required this.onPickColor,
    required this.onDone,
  });

  final MarkupKind activeTool;
  final ValueChanged<MarkupKind> onPickTool;
  final Color activeColor;
  final List<Color> colorPresets;
  final ValueChanged<Color> onPickColor;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            SegmentedButton<MarkupKind>(
              segments: const [
                ButtonSegment(
                  value: MarkupKind.circle,
                  label: Text('Circle'),
                  icon: Icon(Icons.radio_button_unchecked),
                ),
                ButtonSegment(
                  value: MarkupKind.line,
                  label: Text('Line'),
                  icon: Icon(Icons.show_chart),
                ),
              ],
              selected: {activeTool},
              showSelectedIcon: true,
              onSelectionChanged: (set) =>
                  onPickTool(set.isEmpty ? activeTool : set.first),
            ),
            const SizedBox(width: 8),
            _ColorSwatchRow(
              presets: colorPresets,
              active: activeColor,
              onPick: onPickColor,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: onDone,
              icon: const Icon(Icons.check),
              label: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatchRow extends StatelessWidget {
  const _ColorSwatchRow({
    required this.presets,
    required this.active,
    required this.onPick,
  });

  final List<Color> presets;
  final Color active;
  final ValueChanged<Color> onPick;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in presets)
          SizedBox(
            width: 40,
            height: 40,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => onPick(c),
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c.toARGB32() == active.toARGB32()
                          ? onSurface
                          : onSurface.withValues(alpha: 0.25),
                      width: c.toARGB32() == active.toARGB32() ? 3 : 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
