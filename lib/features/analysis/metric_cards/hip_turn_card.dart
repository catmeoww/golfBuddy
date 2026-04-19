import 'package:flutter/widgets.dart';

import '../../../domain/models/metric.dart';
import 'metric_card.dart';

class HipTurnCard extends StatelessWidget {
  const HipTurnCard({required this.metric, super.key});

  final Metric metric;

  @override
  Widget build(BuildContext context) {
    return MetricCard(
      title: 'Hip turn',
      valueText: '${metric.value.toStringAsFixed(0)}°',
      bandLabel: metric.bandLabel,
      subtitle: 'used frames A / T',
    );
  }
}
