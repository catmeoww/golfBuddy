import '../../../domain/models/metric.dart';
import '../../../domain/models/phase.dart';
import '../../../domain/models/pose_frame.dart';
import '../../../domain/models/swing_analysis.dart';

/// LLD §4 — tempo ratio = (top - address) / (impact - top).
/// Bands: 2.8–3.2 = good, 2.5–3.5 = fair, else = off.
class TempoCalculator {
  const TempoCalculator();

  static const metricName = 'tempo_ratio';

  Metric? call(List<PoseFrame> frames, List<PhaseMarker> phases) {
    final address = _find(phases, SwingPhase.address);
    final top = _find(phases, SwingPhase.top);
    final impact = _find(phases, SwingPhase.impact);
    if (address == null || top == null || impact == null) return null;
    final backswingMs = top.timestampMs - address.timestampMs;
    final downswingMs = impact.timestampMs - top.timestampMs;
    if (backswingMs <= 0 || downswingMs <= 0) {
      return Metric(
        name: metricName,
        value: 0,
        confidence: 0.0,
        bandLabel: 'off',
      );
    }
    final ratio = backswingMs / downswingMs;
    final band = _band(ratio);
    final confidence = _avgPhaseConfidence([address, top, impact]);
    return Metric(
      name: metricName,
      value: ratio,
      confidence: confidence,
      bandLabel: band,
    );
  }

  static String _band(double ratio) {
    if (ratio >= 2.8 && ratio <= 3.2) return 'good';
    if (ratio >= 2.5 && ratio <= 3.5) return 'fair';
    return 'off';
  }

  static PhaseMarker? _find(List<PhaseMarker> phases, SwingPhase phase) {
    for (final p in phases) {
      if (p.phase == phase) return p;
    }
    return null;
  }

  static double _avgPhaseConfidence(List<PhaseMarker> ms) {
    if (ms.isEmpty) return 0.0;
    var s = 0.0;
    for (final m in ms) {
      s += m.confidence;
    }
    return s / ms.length;
  }
}
