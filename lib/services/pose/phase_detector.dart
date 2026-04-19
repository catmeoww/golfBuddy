import 'dart:math' as math;

import '../../domain/models/phase.dart';
import '../../domain/models/pose_frame.dart';
import '../../domain/models/swing_analysis.dart';

/// LLD §4 — heuristic v0 phase detector.
/// Works on smoothed wrist-Y trajectory + velocity zero-crossings.
class PhaseDetector {
  const PhaseDetector({
    this.smoothingWindow = 5,
    this.addressStableFrames = 10,
    this.addressVarianceEpsilon = 0.002,
  });

  final int smoothingWindow;
  final int addressStableFrames;
  final double addressVarianceEpsilon;

  List<PhaseMarker> detect(List<PoseFrame> frames) {
    if (frames.length < addressStableFrames + 4) {
      return _fallbackEvenSplit(frames);
    }
    // Use the dominant wrist; default to right wrist for a right-handed
    // golfer. If missing in early frames, fall back to left.
    final wristJoint = _pickWrist(frames);
    final wristYs = <double>[];
    final wristXs = <double>[];
    for (final f in frames) {
      final w = f.joints[wristJoint];
      wristYs.add(w?.y ?? double.nan);
      wristXs.add(w?.x ?? double.nan);
    }
    final smoothedY = _movingAverage(wristYs, smoothingWindow);
    final smoothedX = _movingAverage(wristXs, smoothingWindow);

    final addressIdx = _detectAddress(smoothedY);
    // "top" = max wrist Y (image Y grows downward in screen coords; in our
    // normalized joints we treat "top of swing" as the frame farthest from
    // address along wrist-Y — pick max absolute deviation).
    final topIdx = _detectTop(smoothedY, addressIdx);
    final impactIdx = _detectImpact(smoothedY, smoothedX, addressIdx, topIdx);
    final finishIdx = _detectFinish(smoothedY, impactIdx);

    final addressConf = _trajectoryStability(smoothedY, addressIdx);
    final topConf = _extremumConfidence(smoothedY, topIdx);
    final impactConf = _velocityConfidence(smoothedY, impactIdx);
    final finishConf = _trajectoryStability(smoothedY, finishIdx);

    return [
      _marker(frames, SwingPhase.address, addressIdx, addressConf),
      _marker(frames, SwingPhase.top, topIdx, topConf),
      _marker(frames, SwingPhase.impact, impactIdx, impactConf),
      _marker(frames, SwingPhase.finish, finishIdx, finishConf),
    ];
  }

  // -- helpers ---------------------------------------------------------------

  Joint _pickWrist(List<PoseFrame> frames) {
    final sample = frames.take(5);
    var rightHits = 0;
    var leftHits = 0;
    for (final f in sample) {
      if (f.joints[Joint.rightWrist] != null) rightHits++;
      if (f.joints[Joint.leftWrist] != null) leftHits++;
    }
    return rightHits >= leftHits ? Joint.rightWrist : Joint.leftWrist;
  }

  List<double> _movingAverage(List<double> xs, int window) {
    if (window <= 1) return List.of(xs);
    final out = List<double>.filled(xs.length, double.nan);
    final half = window ~/ 2;
    for (var i = 0; i < xs.length; i++) {
      final lo = math.max(0, i - half);
      final hi = math.min(xs.length - 1, i + half);
      var sum = 0.0;
      var count = 0;
      for (var j = lo; j <= hi; j++) {
        if (!xs[j].isNaN) {
          sum += xs[j];
          count++;
        }
      }
      out[i] = count == 0 ? double.nan : sum / count;
    }
    return out;
  }

  int _detectAddress(List<double> ys) {
    for (var i = 0; i + addressStableFrames <= ys.length; i++) {
      final window = ys.sublist(i, i + addressStableFrames);
      if (window.any((v) => v.isNaN)) continue;
      final variance = _variance(window);
      if (variance < addressVarianceEpsilon) return i;
    }
    return 0;
  }

  int _detectTop(List<double> ys, int addressIdx) {
    // Anchored to wrist-Y extremum. Interpret largest deviation from address
    // as "top" (in normalized MLKit coords, up in the frame tends to mean
    // smaller y, but the extremum idea holds regardless of sign).
    final baseline = ys[addressIdx];
    var bestIdx = addressIdx;
    var bestDev = 0.0;
    for (var i = addressIdx + 1; i < ys.length; i++) {
      if (ys[i].isNaN) continue;
      final dev = (ys[i] - baseline).abs();
      if (dev > bestDev) {
        bestDev = dev;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  int _detectImpact(
    List<double> ys,
    List<double> xs,
    int addressIdx,
    int topIdx,
  ) {
    final addressX = xs[addressIdx];
    var bestIdx = topIdx;
    var bestScore = -double.infinity;
    for (var i = topIdx + 1; i < ys.length - 1; i++) {
      if (ys[i].isNaN || ys[i + 1].isNaN) continue;
      final velY = (ys[i + 1] - ys[i]).abs();
      final xCrossing = addressX.isNaN || xs[i].isNaN
          ? 0.0
          : -(xs[i] - addressX).abs();
      final score = velY + xCrossing;
      if (score > bestScore) {
        bestScore = score;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  int _detectFinish(List<double> ys, int impactIdx) {
    for (var i = impactIdx + addressStableFrames; i < ys.length; i++) {
      final lo = i - addressStableFrames;
      final window = ys.sublist(lo, i);
      if (window.any((v) => v.isNaN)) continue;
      if (_variance(window) < addressVarianceEpsilon * 2) return i;
    }
    return ys.length - 1;
  }

  double _variance(List<double> xs) {
    if (xs.isEmpty) return 0.0;
    final mean = xs.reduce((a, b) => a + b) / xs.length;
    var s = 0.0;
    for (final x in xs) {
      final d = x - mean;
      s += d * d;
    }
    return s / xs.length;
  }

  double _trajectoryStability(List<double> ys, int idx) {
    final lo = math.max(0, idx - 3);
    final hi = math.min(ys.length, idx + 4);
    final window = ys.sublist(lo, hi).where((v) => !v.isNaN).toList();
    if (window.isEmpty) return 0.3;
    final v = _variance(window);
    final normalized = (1.0 - (v / (addressVarianceEpsilon * 4))).clamp(0.0, 1.0);
    return 0.6 + normalized * 0.4;
  }

  double _extremumConfidence(List<double> ys, int idx) {
    if (idx <= 0 || idx >= ys.length - 1) return 0.6;
    final prev = ys[idx - 1];
    final next = ys[idx + 1];
    if (prev.isNaN || next.isNaN || ys[idx].isNaN) return 0.6;
    final sharpness = ((ys[idx] - prev).abs() + (ys[idx] - next).abs()) / 2;
    return (0.6 + sharpness * 4).clamp(0.6, 1.0);
  }

  double _velocityConfidence(List<double> ys, int idx) {
    if (idx <= 0 || idx >= ys.length - 1) return 0.6;
    final prev = ys[idx - 1];
    final next = ys[idx + 1];
    if (prev.isNaN || next.isNaN) return 0.6;
    final vel = (next - prev).abs();
    return (0.6 + vel * 4).clamp(0.6, 1.0);
  }

  PhaseMarker _marker(
    List<PoseFrame> frames,
    SwingPhase phase,
    int idx,
    double confidence,
  ) {
    final clamped = idx.clamp(0, frames.length - 1);
    final f = frames[clamped];
    return PhaseMarker(
      phase: phase,
      frameIndex: f.index,
      timestampMs: f.timestampMs,
      confidence: confidence,
    );
  }

  List<PhaseMarker> _fallbackEvenSplit(List<PoseFrame> frames) {
    if (frames.isEmpty) return const [];
    final n = frames.length;
    final idxs = [0, n ~/ 3, (2 * n) ~/ 3, n - 1];
    const phases = SwingPhase.values;
    return [
      for (var i = 0; i < 4; i++)
        PhaseMarker(
          phase: phases[i],
          frameIndex: frames[idxs[i]].index,
          timestampMs: frames[idxs[i]].timestampMs,
          confidence: 0.3,
        ),
    ];
  }
}
