import 'package:drift/drift.dart';

import '../../domain/models/metric.dart';
import '../db/database.dart';

class TrendPoint {
  const TrendPoint({
    required this.sessionId,
    required this.capturedAt,
    required this.value,
    required this.confidence,
    this.bandLabel,
  });

  final String sessionId;
  final DateTime capturedAt;
  final double value;
  final double confidence;
  final String? bandLabel;
}

class MetricRepository {
  const MetricRepository(this._db);

  final AppDatabase _db;

  Stream<List<Metric>> watchForSession(String sessionId) {
    final query = _db.select(_db.metrics)
      ..where((m) => m.sessionId.equals(sessionId));
    return query.watch().map(
          (rows) => rows.map(_fromRow).toList(growable: false),
        );
  }

  Future<List<Metric>> forSession(String sessionId) async {
    final rows = await (_db.select(_db.metrics)
          ..where((m) => m.sessionId.equals(sessionId)))
        .get();
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<void> replaceForSession(String sessionId, List<Metric> metrics) async {
    await _db.transaction(() async {
      await (_db.delete(_db.metrics)
            ..where((m) => m.sessionId.equals(sessionId)))
          .go();
      for (final m in metrics) {
        await _db.into(_db.metrics).insert(
              MetricsCompanion.insert(
                sessionId: sessionId,
                name: m.name,
                value: m.value,
                confidence: m.confidence,
                bandLabel: Value(m.bandLabel),
              ),
            );
      }
    });
  }

  /// Trend query: all metric values of [name] for a given player, oldest first.
  Future<List<TrendPoint>> trendForPlayer({
    required String playerId,
    required String metricName,
  }) async {
    final query = _db.select(_db.metrics).join([
      innerJoin(
        _db.sessions,
        _db.sessions.id.equalsExp(_db.metrics.sessionId),
      ),
    ])
      ..where(_db.sessions.playerId.equals(playerId) &
          _db.metrics.name.equals(metricName))
      ..orderBy([OrderingTerm(expression: _db.sessions.capturedAt)]);
    final rows = await query.get();
    return rows.map((row) {
      final metric = row.readTable(_db.metrics);
      final session = row.readTable(_db.sessions);
      return TrendPoint(
        sessionId: session.id,
        capturedAt: session.capturedAt,
        value: metric.value,
        confidence: metric.confidence,
        bandLabel: metric.bandLabel,
      );
    }).toList(growable: false);
  }

  Metric _fromRow(MetricRow row) => Metric(
        name: row.name,
        value: row.value,
        confidence: row.confidence,
        bandLabel: row.bandLabel,
      );
}
