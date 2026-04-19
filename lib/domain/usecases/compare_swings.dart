import '../../data/repositories/metric_repository.dart';
import '../models/metric.dart';

class MetricDiff {
  const MetricDiff({
    required this.name,
    this.valueA,
    this.valueB,
  });

  final String name;
  final double? valueA;
  final double? valueB;

  double? get delta =>
      (valueA != null && valueB != null) ? valueB! - valueA! : null;

  int get sign {
    final d = delta;
    if (d == null) return 0;
    if (d > 0) return 1;
    if (d < 0) return -1;
    return 0;
  }
}

/// LLD §8 — produce a MetricDiff list for the compare screen.
class CompareSwings {
  const CompareSwings(this._metrics);

  final MetricRepository _metrics;

  Future<List<MetricDiff>> call(String sessionIdA, String sessionIdB) async {
    final a = await _metrics.forSession(sessionIdA);
    final b = await _metrics.forSession(sessionIdB);
    final names = <String>{
      for (final m in a) m.name,
      for (final m in b) m.name,
    }.toList()
      ..sort();
    Metric? find(List<Metric> list, String name) {
      for (final m in list) {
        if (m.name == name) return m;
      }
      return null;
    }

    return [
      for (final name in names)
        MetricDiff(
          name: name,
          valueA: find(a, name)?.value,
          valueB: find(b, name)?.value,
        ),
    ];
  }
}
