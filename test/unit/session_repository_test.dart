import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golfbuddy/data/db/database.dart';
import 'package:golfbuddy/data/repositories/player_repository.dart';
import 'package:golfbuddy/data/repositories/session_repository.dart';
import 'package:golfbuddy/data/repositories/tournament_repository.dart';
import 'package:golfbuddy/domain/models/player.dart';
import 'package:golfbuddy/domain/models/session.dart';
import 'package:golfbuddy/domain/models/tournament.dart';

void main() {
  late AppDatabase db;
  late PlayerRepository players;
  late SessionRepository sessions;
  late TournamentRepository tournaments;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    players = PlayerRepository(db);
    sessions = SessionRepository(db);
    tournaments = TournamentRepository(db);
  });

  tearDown(() => db.close());

  test('insert + watch by player filter', () async {
    await players.upsert(
      Player(
        id: 'p1',
        name: 'Ethan',
        type: PlayerType.child,
        createdAt: DateTime.now(),
      ),
    );
    await players.upsert(
      Player(
        id: 'p2',
        name: 'Friend',
        type: PlayerType.friend,
        createdAt: DateTime.now(),
      ),
    );

    await sessions.insert(_session('s1', 'p1'));
    await sessions.insert(_session('s2', 'p2'));
    await sessions.insert(_session('s3', 'p1'));

    final ethan = await sessions.watch(const SessionFilter(playerId: 'p1')).first;
    expect(ethan, hasLength(2));
    expect(ethan.map((s) => s.id), containsAll(['s1', 's3']));

    final friend =
        await sessions.watch(const SessionFilter(playerId: 'p2')).first;
    expect(friend, hasLength(1));
    expect(friend.first.id, 's2');
  });

  test('tournament tagging round-trips with relation', () async {
    await players.upsert(
      Player(
        id: 'p1',
        name: 'Ethan',
        type: PlayerType.child,
        createdAt: DateTime.now(),
      ),
    );
    await tournaments.upsert(
      Tournament(
        id: 't1',
        name: 'US Kids Local',
        date: DateTime(2026, 1, 1),
        createdAt: DateTime.now(),
      ),
    );

    await sessions.insert(_session('s1', 'p1',
        tournamentId: 't1', relation: TournamentRelation.before));

    final got = await sessions.findById('s1');
    expect(got?.tournamentId, 't1');
    expect(got?.tournamentRelation, TournamentRelation.before);
  });
}

SwingSession _session(
  String id,
  String playerId, {
  String? tournamentId,
  TournamentRelation? relation,
}) {
  return SwingSession(
    id: id,
    playerId: playerId,
    tournamentId: tournamentId,
    tournamentRelation: relation,
    videoPath: '/tmp/$id.mp4',
    thumbPath: '/tmp/$id.jpg',
    capturedAt: DateTime.now(),
    durationMs: 2000,
    fps: 60,
    quality: AnalysisQuality.pending,
  );
}
