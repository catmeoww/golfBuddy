import 'dart:convert';

// FR-001 — coach-drawn shapes (circle / line) pinned to a video timestamp.
// All shape coordinates are normalized to 0..1 of the video frame:
// circle radius is normalized to width.

enum MarkupKind { circle, line }

MarkupKind _parseKind(String raw) {
  for (final k in MarkupKind.values) {
    if (k.name == raw) return k;
  }
  throw FormatException('Unknown MarkupKind: $raw');
}

abstract class Markup {
  const Markup({
    required this.id,
    required this.sessionId,
    required this.timestampMs,
    required this.color,
    required this.strokeWidth,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final int timestampMs;
  final int color; // ARGB.
  final double strokeWidth;
  final DateTime createdAt;

  MarkupKind get kind;

  /// JSON-serialised shape data (only the kind-specific coords).
  String dataToJson();

  /// Reconstruct a Markup from a stored row.
  static Markup fromRow({
    required String id,
    required String sessionId,
    required int timestampMs,
    required String kind,
    required String dataJson,
    required int color,
    required double strokeWidth,
    required DateTime createdAt,
  }) {
    final k = _parseKind(kind);
    final data = jsonDecode(dataJson) as Map<String, dynamic>;
    switch (k) {
      case MarkupKind.circle:
        return CircleMarkup(
          id: id,
          sessionId: sessionId,
          timestampMs: timestampMs,
          cx: (data['cx'] as num).toDouble(),
          cy: (data['cy'] as num).toDouble(),
          radius: (data['r'] as num).toDouble(),
          color: color,
          strokeWidth: strokeWidth,
          createdAt: createdAt,
        );
      case MarkupKind.line:
        return LineMarkup(
          id: id,
          sessionId: sessionId,
          timestampMs: timestampMs,
          x1: (data['x1'] as num).toDouble(),
          y1: (data['y1'] as num).toDouble(),
          x2: (data['x2'] as num).toDouble(),
          y2: (data['y2'] as num).toDouble(),
          color: color,
          strokeWidth: strokeWidth,
          createdAt: createdAt,
        );
    }
  }
}

class CircleMarkup extends Markup {
  const CircleMarkup({
    required super.id,
    required super.sessionId,
    required super.timestampMs,
    required this.cx,
    required this.cy,
    required this.radius,
    required super.color,
    required super.strokeWidth,
    required super.createdAt,
  });

  final double cx;
  final double cy;
  final double radius;

  @override
  MarkupKind get kind => MarkupKind.circle;

  @override
  String dataToJson() => jsonEncode({'cx': cx, 'cy': cy, 'r': radius});
}

class LineMarkup extends Markup {
  const LineMarkup({
    required super.id,
    required super.sessionId,
    required super.timestampMs,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required super.color,
    required super.strokeWidth,
    required super.createdAt,
  });

  final double x1;
  final double y1;
  final double x2;
  final double y2;

  @override
  MarkupKind get kind => MarkupKind.line;

  @override
  String dataToJson() =>
      jsonEncode({'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2});
}
