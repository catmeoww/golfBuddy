import 'dart:math' as math;

/// A single sample of frame-to-frame motion magnitude.
class MotionSample {
  const MotionSample({required this.timestampMs, required this.magnitude});

  final int timestampMs;
  final double magnitude;

  @override
  String toString() => 'MotionSample($timestampMs ms, mag=$magnitude)';
}

/// Half-open window of high-motion activity in the recording.
class SwingWindow {
  const SwingWindow({required this.startMs, required this.endMs});

  final int startMs;
  final int endMs;

  int get durationMs => endMs - startMs;

  @override
  String toString() => 'SwingWindow($startMs..$endMs ms)';
}

/// Swing detector. Reads motion magnitudes, returns candidate swing windows.
///
/// Algorithm (matches FR-005 spec):
///   1. Smooth the magnitude series with a 3-sample moving average.
///   2. Threshold at `mean + stddev * thresholdK` (default 0.5).
///   3. Group contiguous above-threshold samples into windows.
///   4. Merge windows whose gap is < [mergeGapMs].
///   5. Drop windows shorter than [minDurationMs].
class SwingDetector {
  const SwingDetector({
    this.thresholdK = 0.5,
    this.minDurationMs = 400,
    this.mergeGapMs = 1000,
    this.smoothingWindow = 3,
  });

  final double thresholdK;
  final int minDurationMs;
  final int mergeGapMs;
  final int smoothingWindow;

  List<SwingWindow> detect(List<MotionSample> samples) {
    if (samples.length < 2) return const [];

    // 1. Smooth.
    final smoothed = _movingAverage(samples, smoothingWindow);

    // 2. Threshold.
    final mags = smoothed.map((s) => s.magnitude).toList(growable: false);
    final mean = mags.reduce((a, b) => a + b) / mags.length;
    final variance = mags
            .map((m) => (m - mean) * (m - mean))
            .reduce((a, b) => a + b) /
        mags.length;
    final stddev = math.sqrt(variance);
    // If the series is perfectly flat, there is no "motion above baseline".
    if (stddev <= 1e-9) return const [];
    final threshold = mean + stddev * thresholdK;

    // 3. Group.
    final raw = <SwingWindow>[];
    int? runStartMs;
    int? runEndMs;
    for (final s in smoothed) {
      if (s.magnitude >= threshold) {
        runStartMs ??= s.timestampMs;
        runEndMs = s.timestampMs;
      } else {
        if (runStartMs != null && runEndMs != null) {
          raw.add(SwingWindow(startMs: runStartMs, endMs: runEndMs));
          runStartMs = null;
          runEndMs = null;
        }
      }
    }
    if (runStartMs != null && runEndMs != null) {
      raw.add(SwingWindow(startMs: runStartMs, endMs: runEndMs));
    }

    // 4. Merge near windows.
    final merged = <SwingWindow>[];
    for (final w in raw) {
      if (merged.isEmpty) {
        merged.add(w);
        continue;
      }
      final last = merged.last;
      if (w.startMs - last.endMs < mergeGapMs) {
        merged[merged.length - 1] =
            SwingWindow(startMs: last.startMs, endMs: w.endMs);
      } else {
        merged.add(w);
      }
    }

    // 5. Drop short ones.
    return merged
        .where((w) => w.durationMs >= minDurationMs)
        .toList(growable: false);
  }

  List<MotionSample> _movingAverage(List<MotionSample> input, int window) {
    if (window <= 1 || input.length <= window) return input;
    final half = window ~/ 2;
    final out = <MotionSample>[];
    for (var i = 0; i < input.length; i++) {
      final lo = math.max(0, i - half);
      final hi = math.min(input.length - 1, i + half);
      var sum = 0.0;
      for (var j = lo; j <= hi; j++) {
        sum += input[j].magnitude;
      }
      final avg = sum / (hi - lo + 1);
      out.add(MotionSample(
        timestampMs: input[i].timestampMs,
        magnitude: avg,
      ));
    }
    return out;
  }
}
