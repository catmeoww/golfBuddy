import 'dart:math' as math;

import '../../../domain/models/metric.dart';
import '../../../domain/models/phase.dart';
import '../../../domain/models/pose_frame.dart';
import '../../../domain/models/swing_analysis.dart';

/// LLD §4 — shoulder + hip turn angle between address and top.
/// Shoulder band: ≥80° = good, ≥60° = fair, else off.
/// Hip band:      ≥40° = good, ≥30° = fair, else off.
class RotationCalculator {
  const RotationCalculator();

  static const shoulderMetric = 'shoulder_turn_deg';
  static const hipMetric = 'hip_turn_deg';

  List<Metric> call(List<PoseFrame> frames, List<PhaseMarker> phases) {
    final address = _find(phases, SwingPhase.address);
    final top = _find(phases, SwingPhase.top);
    if (address == null || top == null) return const [];
    final addressFrame = _frameAt(frames, address.frameIndex);
    final topFrame = _frameAt(frames, top.frameIndex);
    if (addressFrame == null || topFrame == null) return const [];
    final confidence =
        (address.confidence + top.confidence +
                addressFrame.confidence + topFrame.confidence) /
            4;

    final shoulder = _turn(
      addressFrame,
      topFrame,
      Joint.leftShoulder,
      Joint.rightShoulder,
    );
    final hip = _turn(
      addressFrame,
      topFrame,
      Joint.leftHip,
      Joint.rightHip,
    );
    return [
      if (shoulder != null)
        Metric(
          name: shoulderMetric,
          value: shoulder,
          confidence: confidence,
          bandLabel: _shoulderBand(shoulder),
        ),
      if (hip != null)
        Metric(
          name: hipMetric,
          value: hip,
          confidence: confidence,
          bandLabel: _hipBand(hip),
        ),
    ];
  }

  static double? _turn(PoseFrame a, PoseFrame b, Joint left, Joint right) {
    final aL = a.joints[left];
    final aR = a.joints[right];
    final bL = b.joints[left];
    final bR = b.joints[right];
    if (aL == null || aR == null || bL == null || bR == null) return null;
    final angleA = math.atan2(aR.y - aL.y, aR.x - aL.x);
    final angleB = math.atan2(bR.y - bL.y, bR.x - bL.x);
    var diff = (angleB - angleA) * 180 / math.pi;
    // normalize to (-180, 180] and return unsigned turn
    while (diff > 180) diff -= 360;
    while (diff <= -180) diff += 360;
    return diff.abs();
  }

  static String _shoulderBand(double v) {
    if (v >= 80) return 'good';
    if (v >= 60) return 'fair';
    return 'off';
  }

  static String _hipBand(double v) {
    if (v >= 40) return 'good';
    if (v >= 30) return 'fair';
    return 'off';
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
