import 'package:flutter/widgets.dart';

import '../../../domain/models/metric.dart';
import 'metric_card.dart';

class HeadStabilityCard extends StatelessWidget {
  const HeadStabilityCard({required this.metric, super.key});

  final Metric metric;

  @override
  Widget build(BuildContext context) {
    return MetricCard(
      title: 'Head stability',
      valueText: '${metric.value.toStringAsFixed(1)} cm',
      bandLabel: metric.bandLabel,
      subtitle: 'used frames A → I',
    );
  }
}
