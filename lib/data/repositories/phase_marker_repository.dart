import 'package:drift/drift.dart';

import '../../domain/models/phase.dart';
import '../../domain/models/swing_analysis.dart';
import '../db/database.dart';

class PhaseMarkerRepository {
  const PhaseMarkerRepository(this._db);

  final AppDatabase _db;

  Stream<List<PhaseMarker>> watchForSession(String sessionId) {
    final query = _db.select(_db.phaseMarkers)
      ..where((p) => p.sessionId.equals(sessionId))
      ..orderBy([(p) => OrderingTerm(expression: p.timestampMs)]);
    return query.watch().map(
          (rows) => rows.map(_fromRow).toList(growable: false),
        );
  }

  Future<List<PhaseMarker>> forSession(String sessionId) async {
    final rows = await (_db.select(_db.phaseMarkers)
          ..where((p) => p.sessionId.equals(sessionId))
          ..orderBy([(p) => OrderingTerm(expression: p.timestampMs)]))
        .get();
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<void> replaceForSession(
    String sessionId,
    List<PhaseMarker> markers,
  ) async {
    await _db.transaction(() async {
      await (_db.delete(_db.phaseMarkers)
            ..where((p) => p.sessionId.equals(sessionId)))
          .go();
      for (final m in markers) {
        await _db.into(_db.phaseMarkers).insert(
              PhaseMarkersCompanion.insert(
                sessionId: sessionId,
                phase: m.phase.name,
                frameIndex: m.frameIndex,
                timestampMs: m.timestampMs,
                confidence: m.confidence,
                manuallyAdjusted: Value(m.manuallyAdjusted),
              ),
            );
      }
    });
  }

  PhaseMarker _fromRow(PhaseMarkerRow row) => PhaseMarker(
        phase: SwingPhase.values.firstWhere(
          (p) => p.name == row.phase,
          orElse: () => SwingPhase.address,
        ),
        frameIndex: row.frameIndex,
        timestampMs: row.timestampMs,
        confidence: row.confidence,
        manuallyAdjusted: row.manuallyAdjusted,
      );
}
