import '../../data/repositories/metric_repository.dart';
import '../../data/repositories/phase_marker_repository.dart';
import '../../data/repositories/pose_frame_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../services/pose/metrics/head_stability.dart';
import '../../services/pose/metrics/rotation.dart';
import '../../services/pose/metrics/tempo.dart';
import '../../services/pose/phase_detector.dart';
import '../../services/pose/pose_detector_service.dart';
import '../../services/video/frame_extractor.dart';
import '../models/metric.dart';
import '../models/pose_frame.dart';
import '../models/session.dart';
import '../models/swing_analysis.dart';

class AnalyzeSwingResult {
  const AnalyzeSwingResult({required this.analysis, this.error});

  final SwingAnalysis analysis;
  final String? error;
}

/// LLD §4 — orchestrator: frame extract → pose → phases → metrics → persist.
class AnalyzeSwing {
  AnalyzeSwing({
    required this.sessionRepository,
    required this.poseFrameRepository,
    required this.phaseMarkerRepository,
    required this.metricRepository,
    FrameExtractor? frameExtractor,
    PoseDetectorService? poseDetector,
    PhaseDetector? phaseDetector,
  })  : frameExtractor = frameExtractor ?? const FrameExtractor(),
        poseDetector = poseDetector ?? PoseDetectorService(),
        phaseDetector = phaseDetector ?? const PhaseDetector();

  final SessionRepository sessionRepository;
  final PoseFrameRepository poseFrameRepository;
  final PhaseMarkerRepository phaseMarkerRepository;
  final MetricRepository metricRepository;
  final FrameExtractor frameExtractor;
  final PoseDetectorService poseDetector;
  final PhaseDetector phaseDetector;

  Future<AnalyzeSwingResult> call(String sessionId) async {
    final session = await sessionRepository.findById(sessionId);
    if (session == null) {
      throw ArgumentError('Unknown session: $sessionId');
    }
    try {
      final extracted = await frameExtractor.extract(
        videoPath: session.videoPath,
        sourceFps: session.fps,
        durationMs: session.durationMs,
        sessionId: sessionId,
      );
      final poseFrames = await poseDetector.detect(extracted);
      final analysis = await _analyzeFromFrames(sessionId, poseFrames);
      await _persist(sessionId, analysis);
      await sessionRepository.updateQuality(sessionId, analysis.quality);
      await frameExtractor.cleanup(sessionId);
      return AnalyzeSwingResult(analysis: analysis);
    } catch (e) {
      await sessionRepository.updateQuality(sessionId, AnalysisQuality.failed);
      await frameExtractor.cleanup(sessionId);
      return AnalyzeSwingResult(
        analysis: SwingAnalysis(
          sessionId: sessionId,
          frames: const [],
          phases: const [],
          metrics: const [],
          quality: AnalysisQuality.failed,
        ),
        error: e.toString(),
      );
    }
  }

  /// Exposed for tests: run metrics + phases over a supplied frame list.
  Future<SwingAnalysis> analyzeFromFrames(
    String sessionId,
    List<PoseFrame> frames,
  ) {
    return _analyzeFromFrames(sessionId, frames);
  }

  Future<SwingAnalysis> _analyzeFromFrames(
    String sessionId,
    List<PoseFrame> frames,
  ) async {
    final phases = phaseDetector.detect(frames);
    final metrics = <Metric>[];
    final tempo = const TempoCalculator().call(frames, phases);
    if (tempo != null) metrics.add(tempo);
    metrics.addAll(const RotationCalculator().call(frames, phases));
    final head = const HeadStabilityCalculator().call(frames, phases);
    if (head != null) metrics.add(head);
    return SwingAnalysis(
      sessionId: sessionId,
      frames: frames,
      phases: phases,
      metrics: metrics,
      quality: _qualityFromPhases(phases),
    );
  }

  AnalysisQuality _qualityFromPhases(List<PhaseMarker> phases) {
    if (phases.isEmpty) return AnalysisQuality.failed;
    final minConf = phases
        .map((p) => p.confidence)
        .reduce((a, b) => a < b ? a : b);
    if (minConf >= 0.6) return AnalysisQuality.ok;
    if (minConf >= 0.4) return AnalysisQuality.partial;
    return AnalysisQuality.failed;
  }

  Future<void> _persist(String sessionId, SwingAnalysis analysis) async {
    await poseFrameRepository.replaceForSession(sessionId, analysis.frames);
    await phaseMarkerRepository.replaceForSession(sessionId, analysis.phases);
    await metricRepository.replaceForSession(sessionId, analysis.metrics);
  }
}
