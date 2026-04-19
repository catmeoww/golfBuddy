import 'package:flutter_test/flutter_test.dart';
import 'package:golfbuddy/domain/models/phase.dart';
import 'package:golfbuddy/domain/models/pose_frame.dart';
import 'package:golfbuddy/domain/models/swing_analysis.dart';
import 'package:golfbuddy/services/pose/metrics/head_stability.dart';
import 'package:golfbuddy/services/pose/metrics/rotation.dart';
import 'package:golfbuddy/services/pose/metrics/tempo.dart';

PoseFrame _frame({
  required int index,
  required int ms,
  required Map<Joint, Vec2> joints,
  double confidence = 0.9,
}) {
  return PoseFrame(
    index: index,
    timestampMs: ms,
    joints: joints,
    confidence: confidence,
  );
}

PhaseMarker _phase(SwingPhase phase, int frameIndex, int ms,
        {double confidence = 0.9}) =>
    PhaseMarker(
      phase: phase,
      frameIndex: frameIndex,
      timestampMs: ms,
      confidence: confidence,
    );

void main() {
  group('TempoCalculator', () {
    test('good band for 3.0 ratio', () {
      final phases = [
        _phase(SwingPhase.address, 0, 0),
        _phase(SwingPhase.top, 60, 900),
        _phase(SwingPhase.impact, 80, 1200),
        _phase(SwingPhase.finish, 120, 1800),
      ];
      final metric = const TempoCalculator().call(const [], phases);
      expect(metric, isNotNull);
      expect(metric!.value, closeTo(3.0, 0.001));
      expect(metric.bandLabel, 'good');
    });

    test('fair band for 3.4 ratio', () {
      final phases = [
        _phase(SwingPhase.address, 0, 0),
        _phase(SwingPhase.top, 60, 1020),
        _phase(SwingPhase.impact, 80, 1320),
        _phase(SwingPhase.finish, 120, 1800),
      ];
      final metric = const TempoCalculator().call(const [], phases);
      expect(metric!.bandLabel, 'fair');
    });

    test('off band for 5.0 ratio', () {
      final phases = [
        _phase(SwingPhase.address, 0, 0),
        _phase(SwingPhase.top, 60, 1000),
        _phase(SwingPhase.impact, 80, 1200),
        _phase(SwingPhase.finish, 120, 1800),
      ];
      final metric = const TempoCalculator().call(const [], phases);
      expect(metric!.value, closeTo(5.0, 0.001));
      expect(metric.bandLabel, 'off');
    });

    test('returns null when required phases missing', () {
      final phases = [
        _phase(SwingPhase.address, 0, 0),
      ];
      expect(const TempoCalculator().call(const [], phases), isNull);
    });
  });

  group('RotationCalculator', () {
    test('shoulder turn >=80° emits good band', () {
      final address = _frame(index: 0, ms: 0, joints: {
        Joint.leftShoulder: const Vec2(0.3, 0.4),
        Joint.rightShoulder: const Vec2(0.7, 0.4),
        Joint.leftHip: const Vec2(0.4, 0.7),
        Joint.rightHip: const Vec2(0.6, 0.7),
      });
      // At top: shoulders rotated 90°.
      final top = _frame(index: 30, ms: 600, joints: {
        Joint.leftShoulder: const Vec2(0.5, 0.2),
        Joint.rightShoulder: const Vec2(0.5, 0.6),
        Joint.leftHip: const Vec2(0.45, 0.65),
        Joint.rightHip: const Vec2(0.55, 0.75),
      });
      final metrics = const RotationCalculator().call(
        [address, top],
        [
          _phase(SwingPhase.address, 0, 0),
          _phase(SwingPhase.top, 30, 600),
        ],
      );
      final shoulder = metrics.firstWhere(
          (m) => m.name == RotationCalculator.shoulderMetric);
      expect(shoulder.value, closeTo(90, 0.1));
      expect(shoulder.bandLabel, 'good');
    });

    test('returns empty when joints missing', () {
      final phases = [
        _phase(SwingPhase.address, 0, 0),
        _phase(SwingPhase.top, 10, 300),
      ];
      expect(const RotationCalculator().call(const [], phases), isEmpty);
    });
  });

  group('HeadStabilityCalculator', () {
    test('reports cm using shoulder-width reference', () {
      final address = _frame(index: 0, ms: 0, joints: {
        Joint.nose: const Vec2(0.5, 0.2),
        Joint.leftShoulder: const Vec2(0.4, 0.35),
        Joint.rightShoulder: const Vec2(0.6, 0.35),
      });
      // nose moves 0.05 in normalized units; shoulder width = 0.2 ≙ 40cm,
      // so 0.05 ≙ 10cm.
      final impact = _frame(index: 10, ms: 400, joints: {
        Joint.nose: const Vec2(0.55, 0.2),
        Joint.leftShoulder: const Vec2(0.4, 0.35),
        Joint.rightShoulder: const Vec2(0.6, 0.35),
      });
      final metric = const HeadStabilityCalculator().call(
        [address, impact],
        [
          _phase(SwingPhase.address, 0, 0),
          _phase(SwingPhase.impact, 10, 400),
        ],
      );
      expect(metric, isNotNull);
      expect(metric!.value, closeTo(10.0, 0.01));
      expect(metric.bandLabel, 'fair');
    });

    test('tiny displacement lands in good band', () {
      final address = _frame(index: 0, ms: 0, joints: {
        Joint.nose: const Vec2(0.5, 0.2),
        Joint.leftShoulder: const Vec2(0.4, 0.35),
        Joint.rightShoulder: const Vec2(0.6, 0.35),
      });
      final impact = _frame(index: 10, ms: 400, joints: {
        Joint.nose: const Vec2(0.505, 0.2),
        Joint.leftShoulder: const Vec2(0.4, 0.35),
        Joint.rightShoulder: const Vec2(0.6, 0.35),
      });
      final metric = const HeadStabilityCalculator().call(
        [address, impact],
        [
          _phase(SwingPhase.address, 0, 0),
          _phase(SwingPhase.impact, 10, 400),
        ],
      );
      expect(metric!.value, closeTo(1.0, 0.01));
      expect(metric.bandLabel, 'good');
    });
  });
}
