import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/di.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/models/annotation.dart';
import '../../domain/models/metric.dart';
import '../../domain/models/session.dart';
import '../../domain/models/swing_analysis.dart';
import '../../domain/models/tournament.dart';
import '../analysis/analysis_controller.dart';
import '../analysis/phase_scrubber.dart';
import '../session_detail/session_detail_controller.dart';

final otherSessionsForPlayerProvider = FutureProvider.family<
    List<SwingSession>, _ComparePickerArgs>((ref, args) async {
  final repo = ref.watch(sessionRepositoryProvider);
  final all = await repo
      .watch(SessionFilter(playerId: args.playerId))
      .first;
  return all.where((s) => s.id != args.excludeId).toList(growable: false);
});

final _compareTournamentsProvider = FutureProvider<List<Tournament>>((ref) {
  return ref.watch(tournamentRepositoryProvider).watchAll().first;
});

class _ComparePickerArgs {
  const _ComparePickerArgs(this.playerId, this.excludeId);
  final String playerId;
  final String excludeId;

  @override
  bool operator ==(Object other) =>
      other is _ComparePickerArgs &&
      playerId == other.playerId &&
      excludeId == other.excludeId;

  @override
  int get hashCode => Object.hash(playerId, excludeId);
}

enum CompareAlignMode { phase, rawTime }

class CompareScreen extends ConsumerWidget {
  const CompareScreen({required this.sessionId, this.otherId, super.key});

  final String sessionId;
  final String? otherId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionByIdProvider(sessionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Compare swings')),
      body: sessionAsync.when(
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Session not found'));
          }
          if (otherId == null) {
            return _PickOther(session: session);
          }
          return _CompareBody(sessionIdA: sessionId, sessionIdB: otherId!);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
      ),
    );
  }
}

class _PickOther extends ConsumerStatefulWidget {
  const _PickOther({required this.session});
  final SwingSession session;

  @override
  ConsumerState<_PickOther> createState() => _PickOtherState();
}

class _PickOtherState extends ConsumerState<_PickOther> {
  bool _alignByTournament = false;

  @override
  Widget build(BuildContext context) {
    final othersAsync = ref.watch(otherSessionsForPlayerProvider(
      _ComparePickerArgs(widget.session.playerId, widget.session.id),
    ));
    return othersAsync.when(
      data: (others) {
        final analyzable = others
            .where((s) =>
                s.quality == AnalysisQuality.ok ||
                s.quality == AnalysisQuality.partial)
            .toList();
        if (analyzable.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No other analyzed swings for this player yet. '
                'Record + analyze another swing to compare.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return Column(
          children: [
            SwitchListTile(
              title: const Text('Align by tournament'),
              subtitle: const Text(
                  'Group by tournament and surface nearest before/after'),
              value: _alignByTournament,
              onChanged: (v) => setState(() => _alignByTournament = v),
            ),
            const Divider(height: 1),
            Expanded(
              child: _alignByTournament
                  ? _buildTournamentGroups(analyzable)
                  : _buildFlatList(analyzable),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  Widget _buildFlatList(List<SwingSession> sessions) {
    return ListView.separated(
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final s = sessions[i];
        return ListTile(
          leading: const Icon(Icons.play_circle_outline),
          title: Text(_fmt(s.capturedAt)),
          subtitle: Text('${s.club ?? 'No club'} · ${s.quality.name}'),
          onTap: () => context.go(
              '/library/sessions/${widget.session.id}/compare/${s.id}'),
        );
      },
    );
  }

  Widget _buildTournamentGroups(List<SwingSession> sessions) {
    final tournamentsAsync = ref.watch(_compareTournamentsProvider);
    return tournamentsAsync.when(
      data: (tournaments) {
        final Map<String?, List<SwingSession>> grouped = {};
        for (final s in sessions) {
          grouped.putIfAbsent(s.tournamentId, () => []).add(s);
        }
        final tournamentById = {for (final t in tournaments) t.id: t};
        return ListView(
          children: [
            for (final entry in grouped.entries)
              ExpansionTile(
                title: Text(
                  entry.key == null
                      ? 'No tournament'
                      : tournamentById[entry.key!]?.name ?? 'Tournament',
                ),
                children: [
                  for (final s in entry.value)
                    ListTile(
                      title: Text(_fmt(s.capturedAt)),
                      subtitle: Text(s.tournamentRelation?.name ?? '—'),
                      onTap: () => context.go(
                        '/library/sessions/${widget.session.id}/compare/${s.id}',
                      ),
                    ),
                ],
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _CompareBody extends ConsumerStatefulWidget {
  const _CompareBody({required this.sessionIdA, required this.sessionIdB});
  final String sessionIdA;
  final String sessionIdB;

  @override
  ConsumerState<_CompareBody> createState() => _CompareBodyState();
}

class _CompareBodyState extends ConsumerState<_CompareBody> {
  VideoPlayerController? _a;
  VideoPlayerController? _b;
  bool _readyA = false;
  bool _readyB = false;
  double _progress = 0; // 0..1
  CompareAlignMode _mode = CompareAlignMode.phase;

  @override
  void dispose() {
    _a?.dispose();
    _b?.dispose();
    super.dispose();
  }

  Future<void> _initA(String path) async {
    if (_a != null) return;
    final c = VideoPlayerController.file(File(path));
    await c.initialize();
    if (!mounted) return;
    setState(() {
      _a = c;
      _readyA = true;
    });
  }

  Future<void> _initB(String path) async {
    if (_b != null) return;
    final c = VideoPlayerController.file(File(path));
    await c.initialize();
    if (!mounted) return;
    setState(() {
      _b = c;
      _readyB = true;
    });
  }

  void _onScrub(double rel, List<PhaseMarker> phasesA,
      List<PhaseMarker> phasesB, SwingSession a, SwingSession b) {
    setState(() => _progress = rel.clamp(0.0, 1.0));
    final (msA, msB) = _mapToTimestamps(rel, phasesA, phasesB, a, b);
    _a?.seekTo(Duration(milliseconds: msA));
    _b?.seekTo(Duration(milliseconds: msB));
  }

  (int, int) _mapToTimestamps(
    double rel,
    List<PhaseMarker> phasesA,
    List<PhaseMarker> phasesB,
    SwingSession a,
    SwingSession b,
  ) {
    if (_mode == CompareAlignMode.rawTime) {
      final msA = (rel * a.durationMs).round();
      final msB = (rel * b.durationMs).round();
      return (msA, msB);
    }
    final aStart = _phaseTs(phasesA, 'address', 0);
    final aEnd = _phaseTs(phasesA, 'finish', a.durationMs);
    final bStart = _phaseTs(phasesB, 'address', 0);
    final bEnd = _phaseTs(phasesB, 'finish', b.durationMs);
    return (
      (aStart + rel * (aEnd - aStart)).round(),
      (bStart + rel * (bEnd - bStart)).round(),
    );
  }

  int _phaseTs(List<PhaseMarker> phases, String name, int fallback) {
    for (final p in phases) {
      if (p.phase.name == name) return p.timestampMs;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final sessionA = ref.watch(sessionByIdProvider(widget.sessionIdA));
    final sessionB = ref.watch(sessionByIdProvider(widget.sessionIdB));
    final metricsAAsync = ref.watch(metricsForSessionProvider(widget.sessionIdA));
    final metricsBAsync = ref.watch(metricsForSessionProvider(widget.sessionIdB));
    final phasesAAsync = ref.watch(phasesForSessionProvider(widget.sessionIdA));
    final phasesBAsync = ref.watch(phasesForSessionProvider(widget.sessionIdB));
    final annotationsAAsync =
        ref.watch(annotationsForSessionProvider(widget.sessionIdA));
    final annotationsBAsync =
        ref.watch(annotationsForSessionProvider(widget.sessionIdB));

    if (sessionA.value == null || sessionB.value == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final a = sessionA.value!;
    final b = sessionB.value!;
    _initA(a.videoPath);
    _initB(b.videoPath);
    final phasesA = phasesAAsync.value ?? const <PhaseMarker>[];
    final phasesB = phasesBAsync.value ?? const <PhaseMarker>[];
    final metricsA = metricsAAsync.value ?? const <Metric>[];
    final metricsB = metricsBAsync.value ?? const <Metric>[];
    final annotations = [
      ...(annotationsAAsync.value ?? const <Annotation>[]),
      ...(annotationsBAsync.value ?? const <Annotation>[]),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _videoTile(_readyA ? _a : null, 'A')),
            Expanded(child: _videoTile(_readyB ? _b : null, 'B')),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: SegmentedButton<CompareAlignMode>(
            segments: const [
              ButtonSegment(
                value: CompareAlignMode.phase,
                label: Text('Align by phase'),
              ),
              ButtonSegment(
                value: CompareAlignMode.rawTime,
                label: Text('Align by raw time'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
        ),
        Slider(
          value: _progress,
          onChanged: (v) => _onScrub(v, phasesA, phasesB, a, b),
        ),
        PhaseScrubber(
          durationMs: a.durationMs,
          positionMs: (_progress * a.durationMs).round(),
          phases: phasesA,
          annotations: annotations,
          onSeek: (ms) {
            final rel = a.durationMs == 0 ? 0.0 : ms / a.durationMs;
            _onScrub(rel, phasesA, phasesB, a, b);
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: _MetricDiffTable(metricsA: metricsA, metricsB: metricsB),
        ),
      ],
    );
  }

  Widget _videoTile(VideoPlayerController? c, String label) {
    if (c == null || !c.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 9 / 16,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return AspectRatio(
      aspectRatio: c.value.aspectRatio == 0 ? 9 / 16 : c.value.aspectRatio,
      child: Stack(
        children: [
          VideoPlayer(c),
          Positioned(
            left: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(label,
                  style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDiffTable extends StatelessWidget {
  const _MetricDiffTable({required this.metricsA, required this.metricsB});

  final List<Metric> metricsA;
  final List<Metric> metricsB;

  @override
  Widget build(BuildContext context) {
    final names = <String>{
      for (final m in metricsA) m.name,
      for (final m in metricsB) m.name,
    }.toList()
      ..sort();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('Metric diff', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final name in names)
          _diffRow(
            context,
            name,
            _findByName(metricsA, name),
            _findByName(metricsB, name),
          ),
      ],
    );
  }

  Metric? _findByName(List<Metric> list, String name) {
    for (final m in list) {
      if (m.name == name) return m;
    }
    return null;
  }

  Widget _diffRow(BuildContext ctx, String name, Metric? a, Metric? b) {
    final av = a?.value;
    final bv = b?.value;
    final delta = (av != null && bv != null) ? bv - av : null;
    final arrow = delta == null
        ? '—'
        : delta > 0
            ? '▲'
            : delta < 0
                ? '▼'
                : '→';
    return ListTile(
      dense: true,
      title: Text(name),
      subtitle: Text(
          'A: ${av?.toStringAsFixed(2) ?? '—'} · B: ${bv?.toStringAsFixed(2) ?? '—'}'),
      trailing: Text(
        '$arrow ${delta?.toStringAsFixed(2) ?? ''}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

