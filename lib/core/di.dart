import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/files/video_storage.dart';
import '../data/repositories/annotation_repository.dart';
import '../data/repositories/markup_repository.dart';
import '../data/repositories/metric_repository.dart';
import '../data/repositories/phase_marker_repository.dart';
import '../data/repositories/player_repository.dart';
import '../data/repositories/pose_frame_repository.dart';
import '../data/repositories/session_repository.dart';
import '../data/repositories/tournament_repository.dart';
import '../domain/usecases/analyze_swing.dart';
import '../domain/usecases/delete_session.dart';
import '../domain/usecases/split_long_recording.dart';
import '../domain/usecases/wipe_all_data.dart';
import '../features/capture/save_session_usecase.dart';
import '../services/video/frame_extractor.dart';

// Single app-scoped Drift database. See LLD §5.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final videoStorageProvider = Provider<VideoStorage>((ref) => VideoStorage());

final playerRepositoryProvider = Provider<PlayerRepository>(
  (ref) => PlayerRepository(ref.watch(appDatabaseProvider)),
);

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(ref.watch(appDatabaseProvider)),
);

final tournamentRepositoryProvider = Provider<TournamentRepository>(
  (ref) => TournamentRepository(ref.watch(appDatabaseProvider)),
);

final annotationRepositoryProvider = Provider<AnnotationRepository>(
  (ref) => AnnotationRepository(ref.watch(appDatabaseProvider)),
);

final markupRepositoryProvider = Provider<MarkupRepository>(
  (ref) => MarkupRepository(ref.watch(appDatabaseProvider)),
);

final metricRepositoryProvider = Provider<MetricRepository>(
  (ref) => MetricRepository(ref.watch(appDatabaseProvider)),
);

final phaseMarkerRepositoryProvider = Provider<PhaseMarkerRepository>(
  (ref) => PhaseMarkerRepository(ref.watch(appDatabaseProvider)),
);

final poseFrameRepositoryProvider = Provider<PoseFrameRepository>(
  (ref) => PoseFrameRepository(ref.watch(appDatabaseProvider)),
);

final analyzeSwingProvider = Provider<AnalyzeSwing>(
  (ref) => AnalyzeSwing(
    sessionRepository: ref.watch(sessionRepositoryProvider),
    poseFrameRepository: ref.watch(poseFrameRepositoryProvider),
    phaseMarkerRepository: ref.watch(phaseMarkerRepositoryProvider),
    metricRepository: ref.watch(metricRepositoryProvider),
  ),
);

final deleteSessionProvider = Provider<DeleteSession>(
  (ref) => DeleteSession(
    db: ref.watch(appDatabaseProvider),
    storage: ref.watch(videoStorageProvider),
  ),
);

final wipeAllDataProvider = Provider<WipeAllData>(
  (ref) => WipeAllData(
    db: ref.watch(appDatabaseProvider),
    storage: ref.watch(videoStorageProvider),
  ),
);

final frameExtractorProvider =
    Provider<FrameExtractor>((ref) => const FrameExtractor());

final splitLongRecordingProvider = Provider<SplitLongRecording>(
  (ref) => SplitLongRecording(
    frameExtractor: ref.watch(frameExtractorProvider),
    saveSession: ref.watch(saveSessionProvider),
  ),
);

final appVersionProvider = Provider<String>((ref) => '0.1.0');
