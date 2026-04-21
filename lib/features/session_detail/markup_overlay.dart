import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/markup.dart';

// FR-001 — paints persisted Markups for the active timestamp and, when
// drawMode is on, captures pan gestures to create a new circle/line and
// hands it back via [onDrawn]. Outside drawMode, taps inside an existing
// shape's hit-region call [onTapMarkup].
class MarkupOverlay extends StatefulWidget {
  const MarkupOverlay({
    required this.markups,
    required this.positionMs,
    required this.drawMode,
    required this.activeTool,
    required this.color,
    required this.strokeWidth,
    required this.sessionId,
    required this.onDrawn,
    required this.onTapMarkup,
    this.windowMs = 200,
    super.key,
  });

  final List<Markup> markups;
  final int positionMs;
  final bool drawMode;
  final MarkupKind activeTool;
  final Color color;
  final double strokeWidth;
  final String sessionId;
  final int windowMs;
  final void Function(Markup) onDrawn;
  final void Function(Markup) onTapMarkup;

  @override
  State<MarkupOverlay> createState() => _MarkupOverlayState();
}

class _MarkupOverlayState extends State<MarkupOverlay> {
  Offset? _start; // pixel coords during an active drag
  Offset? _current;

  String _newId() =>
      'mk-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  // FR-001 follow-up: markups are now persistent reference shapes — they
  // stay visible across the whole clip regardless of scrubber position
  // so the coach can watch the head leave or stay inside the circle.
  List<Markup> _visible() => widget.markups;

  void _handleTap(Offset local, Size size) {
    if (widget.drawMode) return;
    // hit-test most-recently-drawn first
    final visible = _visible().reversed.toList(growable: false);
    final nx = local.dx / size.width;
    final ny = local.dy / size.height;
    for (final m in visible) {
      if (_hits(m, nx, ny, size)) {
        widget.onTapMarkup(m);
        return;
      }
    }
  }

  bool _hits(Markup m, double nx, double ny, Size size) {
    // tolerance ~12px in widget coords, normalised to width
    final tolN = 12.0 / size.width;
    if (m is CircleMarkup) {
      final dx = nx - m.cx;
      final dy = ny - m.cy;
      final dist = math.sqrt(dx * dx + dy * dy);
      return (dist - m.radius).abs() <= tolN;
    } else if (m is LineMarkup) {
      return _distToSegment(nx, ny, m.x1, m.y1, m.x2, m.y2) <= tolN;
    }
    return false;
  }

  void _onPanStart(DragStartDetails d) {
    if (!widget.drawMode) return;
    setState(() {
      _start = d.localPosition;
      _current = d.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!widget.drawMode) return;
    setState(() => _current = d.localPosition);
  }

  void _onPanEnd(DragEndDetails _, Size size) {
    if (!widget.drawMode) return;
    final s = _start;
    final c = _current;
    setState(() {
      _start = null;
      _current = null;
    });
    if (s == null || c == null) return;
    if ((s - c).distance < 4) return; // ignore tiny drags
    final now = DateTime.now();
    final id = _newId();
    final color = widget.color.toARGB32();
    if (widget.activeTool == MarkupKind.circle) {
      // center = midpoint, radius = half of drag length
      final cx = ((s.dx + c.dx) / 2) / size.width;
      final cy = ((s.dy + c.dy) / 2) / size.height;
      final r = ((s - c).distance / 2) / size.width;
      widget.onDrawn(CircleMarkup(
        id: id,
        sessionId: widget.sessionId,
        timestampMs: widget.positionMs,
        cx: cx,
        cy: cy,
        radius: r,
        color: color,
        strokeWidth: widget.strokeWidth,
        createdAt: now,
      ));
    } else {
      widget.onDrawn(LineMarkup(
        id: id,
        sessionId: widget.sessionId,
        timestampMs: widget.positionMs,
        x1: s.dx / size.width,
        y1: s.dy / size.height,
        x2: c.dx / size.width,
        y2: c.dy / size.height,
        color: color,
        strokeWidth: widget.strokeWidth,
        createdAt: now,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _handleTap(d.localPosition, size),
          onPanStart: widget.drawMode ? _onPanStart : null,
          onPanUpdate: widget.drawMode ? _onPanUpdate : null,
          onPanEnd: widget.drawMode ? (d) => _onPanEnd(d, size) : null,
          child: CustomPaint(
            size: size,
            painter: _MarkupPainter(
              markups: _visible(),
              previewStart: _start,
              previewEnd: _current,
              previewKind: widget.activeTool,
              previewColor: widget.color,
              previewStrokeWidth: widget.strokeWidth,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }

  static double _distToSegment(
      double px, double py, double ax, double ay, double bx, double by) {
    final dx = bx - ax;
    final dy = by - ay;
    final lenSq = dx * dx + dy * dy;
    double t = lenSq == 0 ? 0 : ((px - ax) * dx + (py - ay) * dy) / lenSq;
    if (t < 0) {
      t = 0;
    } else if (t > 1) {
      t = 1;
    }
    final cx = ax + t * dx;
    final cy = ay + t * dy;
    final ex = px - cx;
    final ey = py - cy;
    return math.sqrt(ex * ex + ey * ey);
  }
}

class _MarkupPainter extends CustomPainter {
  _MarkupPainter({
    required this.markups,
    required this.previewStart,
    required this.previewEnd,
    required this.previewKind,
    required this.previewColor,
    required this.previewStrokeWidth,
  });

  final List<Markup> markups;
  final Offset? previewStart;
  final Offset? previewEnd;
  final MarkupKind previewKind;
  final Color previewColor;
  final double previewStrokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    for (final m in markups) {
      _drawMarkup(canvas, size, m);
    }
    if (previewStart != null && previewEnd != null) {
      final paint = Paint()
        ..color = previewColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = previewStrokeWidth
        ..strokeCap = StrokeCap.round;
      if (previewKind == MarkupKind.circle) {
        final center = Offset(
          (previewStart!.dx + previewEnd!.dx) / 2,
          (previewStart!.dy + previewEnd!.dy) / 2,
        );
        final r = (previewStart! - previewEnd!).distance / 2;
        canvas.drawCircle(center, r, paint);
      } else {
        canvas.drawLine(previewStart!, previewEnd!, paint);
      }
    }
  }

  void _drawMarkup(Canvas canvas, Size size, Markup m) {
    final paint = Paint()
      ..color = Color(m.color)
      ..style = PaintingStyle.stroke
      ..strokeWidth = m.strokeWidth
      ..strokeCap = StrokeCap.round;
    if (m is CircleMarkup) {
      final center = Offset(m.cx * size.width, m.cy * size.height);
      // Radius normalised to width — keeps shape proportional with frame.
      final r = m.radius * size.width;
      canvas.drawCircle(center, r, paint);
    } else if (m is LineMarkup) {
      canvas.drawLine(
        Offset(m.x1 * size.width, m.y1 * size.height),
        Offset(m.x2 * size.width, m.y2 * size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MarkupPainter old) {
    return old.markups != markups ||
        old.previewStart != previewStart ||
        old.previewEnd != previewEnd ||
        old.previewKind != previewKind ||
        old.previewColor != previewColor ||
        old.previewStrokeWidth != previewStrokeWidth;
  }
}
