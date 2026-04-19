enum AnalysisQuality {
  pending,
  ok,
  partial,
  failed;

  static AnalysisQuality parse(String raw) {
    return AnalysisQuality.values.firstWhere(
      (q) => q.name == raw,
      orElse: () => AnalysisQuality.pending,
    );
  }
}

enum TournamentRelation {
  before,
  during,
  after;

  static TournamentRelation? tryParse(String? raw) {
    if (raw == null) return null;
    for (final r in TournamentRelation.values) {
      if (r.name == raw) return r;
    }
    return null;
  }
}

class SwingSession {
  const SwingSession({
    required this.id,
    required this.playerId,
    required this.videoPath,
    required this.thumbPath,
    required this.capturedAt,
    required this.durationMs,
    required this.fps,
    required this.quality,
    this.tournamentId,
    this.tournamentRelation,
    this.club,
  });

  final String id;
  final String playerId;
  final String? tournamentId;
  final TournamentRelation? tournamentRelation;
  final String? club;
  final String videoPath;
  final String thumbPath;
  final DateTime capturedAt;
  final int durationMs;
  final int fps;
  final AnalysisQuality quality;
}
