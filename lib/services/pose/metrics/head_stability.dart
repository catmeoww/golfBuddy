import 'dart:math' as math;

import '../../../domain/models/metric.dart';
import '../../../domain/models/phase.dart';
import '../../../domain/models/pose_frame.dart';
import '../../../domain/models/swing_analysis.dart';

/// LLD §4 — nose displacement from address to impact, scaled using
/// shoulder-width as a 40cm reference. Bands (cm): <5 good, 5–10 fair, >10 off.
class HeadStabilityCalculator {
  const HeadStabilityCalculator();

  static const metricName = 'head_stability_cm';
  static const referenceShoulderWidthCm = 40.0;

  Metric? call(List<PoseFrame> frames, List<PhaseMarker> phases) {
    final address = _find(phases, SwingPhase.address);
    final impact = _find(phases, SwingPhase.impact);
    if (address == null || impact == null) return null;
    final range = frames.where(
      (f) =>
          f.index >= address.frameIndex && f.index <= impact.frameIndex,
    );
    if (range.isEmpty) return null;
    final anchor = _frameAt(frames, address.frameIndex);
    if (anchor == null) return null;
    final nose0 = anchor.joints[Joint.nose];
    final shoulderL = anchor.joints[Joint.leftShoulder];
    final shoulderR = anchor.joints[Joint.rightShoulder];
    if (nose0 == null || shoulderL == null || shoulderR == null) return null;

    final shoulderWidthNorm = _dist(shoulderL, shoulderR);
    if (shoulderWidthNorm <= 0.0001) return null;
    final cmPerNormUnit = referenceShoulderWidthCm / shoulderWidthNorm;

    var maxDisp = 0.0;
    for (final f in range) {
      final nose = f.joints[Joint.nose];
      if (nose == null) continue;
      final d = _dist(nose, nose0);
      if (d > maxDisp) maxDisp = d;
    }
    final cm = maxDisp * cmPerNormUnit;
    final confidence = (address.confidence + impact.confidence) / 2;
    return Metric(
      name: metricName,
      value: cm,
      confidence: confidence,
      bandLabel: _band(cm),
    );
  }

  static String _band(double cm) {
    if (cm < 5) return 'good';
    if (cm <= 10) return 'fair';
    return 'off';
  }

  static double _dist(Vec2 a, Vec2 b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  static PhaseMarker? _find(List<PhaseMarker> phases, SwingPhase phase) {
    for (final p in phases) {
      if (p.phase == phase) return p;
    }
    return null;
  }

  static PoseFrame? _frameAt(List<PoseFrame> frames, int frameIndex) {
    for (final f in frames) {
      if (f.index == frameIndex) return f;
    }
    return frames.isEmpty ? null : frames.first;
  }
}
