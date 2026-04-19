import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di.dart';
import '../../data/repositories/metric_repository.dart';
import '../../domain/models/tournament.dart';
import '../../services/pose/metrics/head_stability.dart';
import '../../services/pose/metrics/rotation.dart';
import '../../services/pose/metrics/tempo.dart';
import 'trend_chart.dart';

class _TrendArgs {
  const _TrendArgs(this.playerId, this.metricName);
  final String playerId;
  final String metricName;

  @override
  bool operator ==(Object other) =>
      other is _TrendArgs &&
      playerId == other.playerId &&
      metricName == other.metricName;

  @override
  int get hashCode => Object.hash(playerId, metricName);
}

final _trendPointsProvider =
    FutureProvider.family<List<TrendPoint>, _TrendArgs>((ref, args) async {
  return ref.watch(metricRepositoryProvider).trendForPlayer(
        playerId: args.playerId,
        metricName: args.metricName,
      );
});

final _tournamentsProvider = FutureProvider<List<Tournament>>((ref) {
  return ref.watch(tournamentRepositoryProvider).watchAll().first;
});

const _metricOptions = <({String name, String label})>[
  (name: TempoCalculator.metricName, label: 'Tempo'),
  (name: RotationCalculator.shoulderMetric, label: 'Shoulder turn'),
  (name: RotationCalculator.hipMetric, label: 'Hip turn'),
  (name: HeadStabilityCalculator.metricName, label: 'Head stability'),
];

class TrendScreen extends ConsumerStatefulWidget {
  const TrendScreen({required this.playerId, required this.metricName, super.key});

  final String playerId;
  final String metricName;

  @override
  ConsumerState<TrendScreen> createState() => _TrendScreenState();
}

class _TrendScreenState extends ConsumerState<TrendScreen> {
  late String _metricName = widget.metricName;

  @override
  Widget build(BuildContext context) {
    final pointsAsync = ref.watch(
        _trendPointsProvider(_TrendArgs(widget.playerId, _metricName)));
    final tournamentsAsync = ref.watch(_tournamentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Trend')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButton<String>(
              value: _metricName,
              isExpanded: true,
              items: [
                for (final opt in _metricOptions)
                  DropdownMenuItem(value: opt.name, child: Text(opt.label)),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _metricName = v);
              },
            ),
          ),
          Expanded(
            child: pointsAsync.when(
              data: (points) => Padding(
                padding: const EdgeInsets.all(16),
                child: TrendChart(
                  points: points,
                  tournaments: tournamentsAsync.value ?? const <Tournament>[],
                  onTapPoint: (p) =>
                      context.go('/library/sessions/${p.sessionId}'),
                ),
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }
}
