import 'package:drift/drift.dart';

import '../../domain/models/session.dart';
import '../db/database.dart';

class SessionFilter {
  const SessionFilter({this.playerId, this.tournamentId, this.club});

  final String? playerId;
  final String? tournamentId;
  final String? club;
}

class SessionRepository {
  const SessionRepository(this._db);

  final AppDatabase _db;

  Stream<List<SwingSession>> watch(SessionFilter filter) {
    final query = _db.select(_db.sessions)
      ..orderBy([
        (s) => OrderingTerm(
              expression: s.capturedAt,
              mode: OrderingMode.desc,
            ),
      ]);
    if (filter.playerId != null) {
      query.where((s) => s.playerId.equals(filter.playerId!));
    }
    if (filter.tournamentId != null) {
      query.where((s) => s.tournamentId.equals(filter.tournamentId!));
    }
    if (filter.club != null) {
      query.where((s) => s.club.equals(filter.club!));
    }
    return query.watch().map(
          (rows) => rows.map(_fromRow).toList(growable: false),
        );
  }

  Future<SwingSession?> findById(String id) async {
    final row = await (_db.select(_db.sessions)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<void> insert(SwingSession session) {
    return _db.into(_db.sessions).insert(
          SessionsCompanion.insert(
            id: session.id,
            playerId: session.playerId,
            tournamentId: Value(session.tournamentId),
            tournamentRelation: Value(session.tournamentRelation?.name),
            club: Value(session.club),
            videoPath: session.videoPath,
            thumbPath: session.thumbPath,
            capturedAt: session.capturedAt,
            durationMs: session.durationMs,
            fps: session.fps,
            quality: Value(session.quality.name),
          ),
        );
  }

  Future<void> updateTournament(
    String sessionId,
    String? tournamentId,
    TournamentRelation? relation,
  ) {
    return (_db.update(_db.sessions)..where((s) => s.id.equals(sessionId)))
        .write(
      SessionsCompanion(
        tournamentId: Value(tournamentId),
        tournamentRelation: Value(relation?.name),
      ),
    );
  }

  Future<void> delete(String id) {
    return (_db.delete(_db.sessions)..where((s) => s.id.equals(id))).go();
  }

  SwingSession _fromRow(SessionRow row) => SwingSession(
        id: row.id,
        playerId: row.playerId,
        tournamentId: row.tournamentId,
        tournamentRelation:
            TournamentRelation.tryParse(row.tournamentRelation),
        club: row.club,
        videoPath: row.videoPath,
        thumbPath: row.thumbPath,
        capturedAt: row.capturedAt,
        durationMs: row.durationMs,
        fps: row.fps,
        quality: AnalysisQuality.parse(row.quality),
      );
}
