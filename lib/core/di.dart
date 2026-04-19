import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/files/video_storage.dart';
import '../data/repositories/annotation_repository.dart';
import '../data/repositories/player_repository.dart';
import '../data/repositories/session_repository.dart';
import '../data/repositories/tournament_repository.dart';

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

final appVersionProvider = Provider<String>((ref) => '0.1.0');
