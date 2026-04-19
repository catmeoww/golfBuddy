import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golfbuddy/data/db/database.dart';
import 'package:golfbuddy/data/repositories/annotation_repository.dart';
import 'package:golfbuddy/data/repositories/player_repository.dart';
import 'package:golfbuddy/data/repositories/session_repository.dart';
import 'package:golfbuddy/domain/models/annotation.dart';
import 'package:golfbuddy/domain/models/player.dart';
import 'package:golfbuddy/domain/models/session.dart';

void main() {
  late AppDatabase db;
  late PlayerRepository players;
  late SessionRepository sessions;
  late AnnotationRepository annotations;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    players = PlayerRepository(db);
    sessions = SessionRepository(db);
    annotations = AnnotationRepository(db);
    await players.upsert(
      Player(
        id: 'p1',
        name: 'Ethan',
        type: PlayerType.child,
        createdAt: DateTime.now(),
      ),
    );
    await sessions.insert(
      SwingSession(
        id: 's1',
        playerId: 'p1',
        videoPath: '/tmp/s1.mp4',
        thumbPath: '/tmp/s1.jpg',
        capturedAt: DateTime.now(),
        durationMs: 1500,
        fps: 60,
        quality: AnalysisQuality.pending,
      ),
    );
  });

  tearDown(() => db.close());

  test('session + anchored notes both round-trip', () async {
    await annotations.insert(
      Annotation(
        id: 'a1',
        sessionId: 's1',
        text: 'Looked tired today',
        createdAt: DateTime.now(),
      ),
    );
    await annotations.insert(
      Annotation(
        id: 'a2',
        sessionId: 's1',
        timestampMs: 750,
        text: 'Hips open early',
        createdAt: DateTime.now(),
      ),
    );

    final all = await annotations.watchForSession('s1').first;
    expect(all, hasLength(2));

    final anchored = all.where((a) => a.timestampMs != null).toList();
    expect(anchored, hasLength(1));
    expect(anchored.first.text, 'Hips open early');
    expect(anchored.first.timestampMs, 750);

    final sessionLevel = all.where((a) => a.timestampMs == null).toList();
    expect(sessionLevel, hasLength(1));
    expect(sessionLevel.first.text, 'Looked tired today');
  });
}
