import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/annotations.dart';
import 'tables/metrics.dart';
import 'tables/phase_markers.dart';
import 'tables/players.dart';
import 'tables/pose_frames.dart';
import 'tables/sessions.dart';
import 'tables/tournaments.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Players,
    Sessions,
    PhaseMarkers,
    Metrics,
    Tournaments,
    Annotations,
    PoseFrames,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(tournaments);
            await m.createTable(annotations);
            await m.addColumn(players, players.playerType);
            await m.addColumn(sessions, sessions.tournamentId);
            await m.addColumn(sessions, sessions.tournamentRelation);
          }
          if (from < 3) {
            // v3: additive — cache pose detections so analysis replays offline.
            await m.createTable(poseFrames);
          }
          await _createIndexes();
        },
      );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sessions_player_time '
      'ON sessions(player_id, captured_at DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sessions_tournament '
      'ON sessions(tournament_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_metrics_session_name '
      'ON metrics(session_id, name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_annotations_session_ts '
      'ON annotations(session_id, timestamp_ms)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_pose_frames_session_time '
      'ON pose_frames(session_id, timestamp_ms)',
    );
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'golfbuddy');
}
