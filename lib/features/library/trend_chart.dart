import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/repositories/metric_repository.dart';
import '../../domain/models/tournament.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({
    required this.points,
    required this.tournaments,
    required this.onTapPoint,
    this.yLabel = '',
    super.key,
  });

  final List<TrendPoint> points;
  final List<Tournament> tournaments;
  final ValueChanged<TrendPoint> onTapPoint;
  final String yLabel;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(child: Text('No data for this metric yet'));
    }
    final xs = points
        .map((p) => p.capturedAt.millisecondsSinceEpoch.toDouble())
        .toList();
    final minX = xs.reduce((a, b) => a < b ? a : b);
    final maxX = xs.reduce((a, b) => a > b ? a : b);
    final spots = <FlSpot>[
      for (final p in points)
        FlSpot(p.capturedAt.millisecondsSinceEpoch.toDouble(), p.value),
    ];
    final vertical = <VerticalLine>[
      for (final t in tournaments)
        if (t.date.millisecondsSinceEpoch.toDouble() >= minX &&
            t.date.millisecondsSinceEpoch.toDouble() <= maxX)
          VerticalLine(
            x: t.date.millisecondsSinceEpoch.toDouble(),
            color: Colors.orange,
            strokeWidth: 1,
            dashArray: [4, 4],
            label: VerticalLineLabel(show: true, labelResolver: (_) => t.name),
          ),
    ];
    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        extraLinesData: ExtraLinesData(verticalLines: vertical),
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            barWidth: 2,
            dotData: const FlDotData(show: true),
          ),
        ],
        lineTouchData: LineTouchData(
          touchCallback: (event, response) {
            if (event is FlTapUpEvent &&
                response?.lineBarSpots != null &&
                response!.lineBarSpots!.isNotEmpty) {
              final spot = response.lineBarSpots!.first;
              final point = points[spot.spotIndex];
              onTapPoint(point);
            }
          },
        ),
      ),
    );
  }
}
