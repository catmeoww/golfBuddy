import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../domain/models/annotation.dart';
import '../../domain/models/player.dart';
import '../../domain/models/session.dart';
import '../../domain/models/tournament.dart';

final sessionByIdProvider =
    FutureProvider.family<SwingSession?, String>((ref, id) {
  return ref.watch(sessionRepositoryProvider).findById(id);
});

final playerByIdProvider =
    FutureProvider.family<Player?, String>((ref, id) {
  return ref.watch(playerRepositoryProvider).findById(id);
});

final tournamentByIdProvider =
    FutureProvider.family<Tournament?, String>((ref, id) {
  return ref.watch(tournamentRepositoryProvider).findById(id);
});

final annotationsForSessionProvider =
    StreamProvider.family<List<Annotation>, String>((ref, sessionId) {
  return ref
      .watch(annotationRepositoryProvider)
      .watchForSession(sessionId);
});
