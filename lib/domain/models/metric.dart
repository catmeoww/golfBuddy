// LLD §2 — Metric model.
class Metric {
  const Metric({
    required this.name,
    required this.value,
    required this.confidence,
    this.bandLabel,
  });

  final String name;
  final double value;
  final double confidence;
  final String? bandLabel;
}
