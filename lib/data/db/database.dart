import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/metrics.dart';
import 'tables/phase_markers.dart';
import 'tables/players.dart';
import 'tables/sessions.dart';

part 'database.g.dart';

// LLD §5 + §9 — Drift database. Schema version tracked for migrations; every
// upgrade must ship a MigrationStrategy.onUpgrade step with a backup step.
@DriftDatabase(tables: [Players, Sessions, PhaseMarkers, Metrics])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Indexes per LLD §5.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_sessions_player_time '
            'ON sessions(player_id, captured_at DESC)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_metrics_session_name '
            'ON metrics(session_id, name)',
          );
        },
        onUpgrade: (m, from, to) async {
          // TODO: add upgrade steps as schemaVersion grows.
        },
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'golfbuddy');
}
