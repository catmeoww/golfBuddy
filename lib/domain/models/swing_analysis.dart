// LLD §2 — SwingAnalysis aggregate.
import 'metric.dart';
import 'phase.dart';
import 'pose_frame.dart';

enum AnalysisQuality { ok, partial, failed }

class PhaseMarker {
  const PhaseMarker({
    required this.phase,
    required this.frameIndex,
    required this.timestampMs,
    required this.confidence,
    this.manuallyAdjusted = false,
  });

  final SwingPhase phase;
  final int frameIndex;
  final int timestampMs;
  final double confidence;
  final bool manuallyAdjusted;
}

class SwingAnalysis {
  const SwingAnalysis({
    required this.sessionId,
    required this.frames,
    required this.phases,
    required this.metrics,
    required this.quality,
  });

  final String sessionId;
  final List<PoseFrame> frames;
  final List<PhaseMarker> phases;
  final List<Metric> metrics;
  final AnalysisQuality quality;
}
