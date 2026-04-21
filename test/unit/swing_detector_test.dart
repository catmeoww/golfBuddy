import 'package:flutter_test/flutter_test.dart';
import 'package:golfbuddy/services/video/swing_detector.dart';

List<MotionSample> _samples(List<double> mags, {int stepMs = 200}) {
  return [
    for (var i = 0; i < mags.length; i++)
      MotionSample(timestampMs: i * stepMs, magnitude: mags[i]),
  ];
}

void main() {
  group('SwingDetector', () {
    test('no motion -> no windows', () {
      final detector = const SwingDetector();
      final out = detector.detect(_samples(List.filled(20, 1.0)));
      expect(out, isEmpty);
    });

    test('two distinct quiet/high bursts -> two windows', () {
      // quiet (10) / high (5) / quiet (10) / high (5) / quiet (10)
      final mags = <double>[];
      mags.addAll(List.filled(10, 1.0));
      mags.addAll(List.filled(5, 20.0));
      mags.addAll(List.filled(10, 1.0));
      mags.addAll(List.filled(5, 20.0));
      mags.addAll(List.filled(10, 1.0));
      final detector = const SwingDetector();
      final out = detector.detect(_samples(mags));
      expect(out.length, 2);
      // First burst starts around index 10 (2000ms) and runs ~800ms.
      expect(out[0].durationMs, greaterThanOrEqualTo(400));
      expect(out[1].durationMs, greaterThanOrEqualTo(400));
      // They should not have been merged.
      expect(out[1].startMs, greaterThan(out[0].endMs));
    });

    test('drops windows shorter than minDurationMs', () {
      // One tiny spike (1 sample = 200ms) and one long burst (5 samples = 1s).
      final mags = <double>[];
      mags.addAll(List.filled(10, 1.0));
      mags.add(20.0); // tiny spike
      mags.addAll(List.filled(10, 1.0));
      mags.addAll(List.filled(5, 20.0));
      mags.addAll(List.filled(10, 1.0));
      final detector = const SwingDetector(minDurationMs: 400);
      final out = detector.detect(_samples(mags));
      // Smoothing can widen the spike slightly; accept 1 window.
      expect(out.length, 1);
      expect(out.first.durationMs, greaterThanOrEqualTo(400));
    });

    test('merges windows closer than mergeGapMs', () {
      // Two bursts with just 1 quiet sample (200ms) between — should merge.
      final mags = <double>[];
      mags.addAll(List.filled(10, 1.0));
      mags.addAll(List.filled(3, 20.0));
      mags.add(1.0); // 200ms quiet gap
      mags.addAll(List.filled(3, 20.0));
      mags.addAll(List.filled(10, 1.0));
      final detector = const SwingDetector(mergeGapMs: 1000);
      final out = detector.detect(_samples(mags));
      expect(out.length, 1);
    });

    test('empty/undersized input returns empty', () {
      final detector = const SwingDetector();
      expect(detector.detect(const []), isEmpty);
      expect(
        detector.detect([const MotionSample(timestampMs: 0, magnitude: 5)]),
        isEmpty,
      );
    });
  });
}
