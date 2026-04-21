import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golfbuddy/data/db/database.dart';
import 'package:golfbuddy/data/repositories/markup_repository.dart';
import 'package:golfbuddy/data/repositories/player_repository.dart';
import 'package:golfbuddy/data/repositories/session_repository.dart';
import 'package:golfbuddy/domain/models/markup.dart';
import 'package:golfbuddy/domain/models/player.dart';
import 'package:golfbuddy/domain/models/session.dart';

void main() {
  late AppDatabase db;
  late MarkupRepository markups;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final players = PlayerRepository(db);
    final sessions = SessionRepository(db);
    markups = MarkupRepository(db);
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

  test('insert + watch round-trips circles and lines, ordered by ts', () async {
    final now = DateTime.now();
    await markups.insert(LineMarkup(
      id: 'l1',
      sessionId: 's1',
      timestampMs: 800,
      x1: 0.1,
      y1: 0.2,
      x2: 0.4,
      y2: 0.6,
      color: 0xFFFFC107,
      strokeWidth: 3.0,
      createdAt: now,
    ));
    await markups.insert(CircleMarkup(
      id: 'c1',
      sessionId: 's1',
      timestampMs: 200,
      cx: 0.5,
      cy: 0.5,
      radius: 0.1,
      color: 0xFFFFC107,
      strokeWidth: 3.0,
      createdAt: now,
    ));

    final all = await markups.watchForSession('s1').first;
    expect(all, hasLength(2));
    expect(all[0], isA<CircleMarkup>());
    expect(all[0].timestampMs, 200);
    expect(all[1], isA<LineMarkup>());
    expect(all[1].timestampMs, 800);

    final c = all[0] as CircleMarkup;
    expect(c.cx, closeTo(0.5, 1e-9));
    expect(c.radius, closeTo(0.1, 1e-9));
  });

  test('delete removes a single markup', () async {
    final now = DateTime.now();
    await markups.insert(CircleMarkup(
      id: 'c1',
      sessionId: 's1',
      timestampMs: 100,
      cx: 0.5,
      cy: 0.5,
      radius: 0.1,
      color: 0xFFFFC107,
      strokeWidth: 3.0,
      createdAt: now,
    ));
    await markups.insert(CircleMarkup(
      id: 'c2',
      sessionId: 's1',
      timestampMs: 200,
      cx: 0.5,
      cy: 0.5,
      radius: 0.1,
      color: 0xFFFFC107,
      strokeWidth: 3.0,
      createdAt: now,
    ));

    await markups.delete('c1');
    final remaining = await markups.watchForSession('s1').first;
    expect(remaining, hasLength(1));
    expect(remaining.single.id, 'c2');
  });

  test('deleteAllForSession nukes everything for that session', () async {
    final now = DateTime.now();
    for (final id in ['a', 'b', 'c']) {
      await markups.insert(CircleMarkup(
        id: id,
        sessionId: 's1',
        timestampMs: 100,
        cx: 0.5,
        cy: 0.5,
        radius: 0.1,
        color: 0xFFFFC107,
        strokeWidth: 3.0,
        createdAt: now,
      ));
    }
    await markups.deleteAllForSession('s1');
    final remaining = await markups.watchForSession('s1').first;
    expect(remaining, isEmpty);
  });

  test('Markup.fromRow / dataToJson round-trips through JSON', () {
    final circle = CircleMarkup(
      id: 'c1',
      sessionId: 's1',
      timestampMs: 500,
      cx: 0.25,
      cy: 0.75,
      radius: 0.12,
      color: 0xFFFFC107,
      strokeWidth: 4.0,
      createdAt: DateTime(2026, 4, 21),
    );
    final json = circle.dataToJson();
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    expect(decoded['cx'], 0.25);
    expect(decoded['r'], 0.12);

    final back = Markup.fromRow(
      id: circle.id,
      sessionId: circle.sessionId,
      timestampMs: circle.timestampMs,
      kind: circle.kind.name,
      dataJson: json,
      color: circle.color,
      strokeWidth: circle.strokeWidth,
      createdAt: circle.createdAt,
    );
    expect(back, isA<CircleMarkup>());
    final back2 = back as CircleMarkup;
    expect(back2.cx, 0.25);
    expect(back2.cy, 0.75);
    expect(back2.radius, 0.12);

    final line = LineMarkup(
      id: 'l1',
      sessionId: 's1',
      timestampMs: 700,
      x1: 0.1,
      y1: 0.2,
      x2: 0.8,
      y2: 0.9,
      color: 0xFFFFC107,
      strokeWidth: 3.0,
      createdAt: DateTime(2026, 4, 21),
    );
    final lback = Markup.fromRow(
      id: line.id,
      sessionId: line.sessionId,
      timestampMs: line.timestampMs,
      kind: line.kind.name,
      dataJson: line.dataToJson(),
      color: line.color,
      strokeWidth: line.strokeWidth,
      createdAt: line.createdAt,
    ) as LineMarkup;
    expect(lback.x1, 0.1);
    expect(lback.y2, 0.9);
  });
}
