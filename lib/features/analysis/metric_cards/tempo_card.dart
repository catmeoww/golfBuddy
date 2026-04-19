import 'package:flutter/widgets.dart';

import '../../../domain/models/metric.dart';
import 'metric_card.dart';

class TempoCard extends StatelessWidget {
  const TempoCard({required this.metric, super.key});

  final Metric metric;

  @override
  Widget build(BuildContext context) {
    return MetricCard(
      title: 'Tempo ratio',
      valueText: metric.value.toStringAsFixed(2),
      bandLabel: metric.bandLabel,
      subtitle: 'used frames A / T / I',
    );
  }
}
