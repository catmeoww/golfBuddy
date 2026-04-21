import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../domain/models/markup.dart';
import '../../domain/models/metric.dart';
import '../../domain/models/pose_frame.dart';
import '../../domain/models/swing_analysis.dart';
import '../../domain/usecases/analyze_swing.dart';

final metricsForSessionProvider =
    StreamProvider.family<List<Metric>, String>((ref, sessionId) {
  return ref.watch(metricRepositoryProvider).watchForSession(sessionId);
});

final phasesForSessionProvider =
    StreamProvider.family<List<PhaseMarker>, String>((ref, sessionId) {
  return ref.watch(phaseMarkerRepositoryProvider).watchForSession(sessionId);
});

final poseFramesForSessionProvider =
    StreamProvider.family<List<PoseFrame>, String>((ref, sessionId) {
  return ref.watch(poseFrameRepositoryProvider).watchForSession(sessionId);
});

final markupsForSessionProvider =
    StreamProvider.family<List<Markup>, String>((ref, sessionId) {
  return ref.watch(markupRepositoryProvider).watchForSession(sessionId);
});

class AnalyzeController extends FamilyAsyncNotifier<AnalyzeSwingResult?, String> {
  @override
  Future<AnalyzeSwingResult?> build(String sessionId) async => null;

  Future<void> run() async {
    state = const AsyncValue.loading();
    final usecase = ref.read(analyzeSwingProvider);
    try {
      final result = await usecase(arg);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final analyzeControllerProvider = AsyncNotifierProvider.family<
    AnalyzeController, AnalyzeSwingResult?, String>(AnalyzeController.new);
