// TODO: LLD §4 — let users drag phase markers; flag manuallyAdjusted=true.
import '../models/phase.dart';

class AdjustPhase {
  const AdjustPhase();

  Future<void> call({
    required String sessionId,
    required SwingPhase phase,
    required int newFrameIndex,
  }) async {
    throw UnimplementedError('AdjustPhase');
  }
}
