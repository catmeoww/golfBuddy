import 'package:flutter/material.dart';

import '../../domain/models/pose_frame.dart';

/// LLD §7 — paints the pose skeleton for the [frame] whose timestamp is
/// closest to [positionMs]. Joints are normalized in [0..1] so we scale
/// to the widget rect. Binary-search by timestamp.
class SkeletonOverlay extends CustomPainter {
  SkeletonOverlay({
    required this.frames,
    required this.positionMs,
    this.strokeWidth = 3.0,
    this.color = const Color(0xFF80FF80),
  });

  final List<PoseFrame> frames;
  final int positionMs;
  final double strokeWidth;
  final Color color;

  static const List<List<Joint>> _bones = [
    [Joint.leftShoulder, Joint.rightShoulder],
    [Joint.leftShoulder, Joint.leftElbow],
    [Joint.leftElbow, Joint.leftWrist],
    [Joint.rightShoulder, Joint.rightElbow],
    [Joint.rightElbow, Joint.rightWrist],
    [Joint.leftShoulder, Joint.leftHip],
    [Joint.rightShoulder, Joint.rightHip],
    [Joint.leftHip, Joint.rightHip],
    [Joint.leftHip, Joint.leftKnee],
    [Joint.leftKnee, Joint.leftAnkle],
    [Joint.rightHip, Joint.rightKnee],
    [Joint.rightKnee, Joint.rightAnkle],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (frames.isEmpty) return;
    final frame = _nearestFrame(positionMs);
    if (frame == null) return;

    final line = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = color;

    Offset? point(Joint j) {
      final v = frame.joints[j];
      if (v == null) return null;
      return Offset(v.x * size.width, v.y * size.height);
    }

    for (final bone in _bones) {
      final a = point(bone[0]);
      final b = point(bone[1]);
      if (a != null && b != null) {
        canvas.drawLine(a, b, line);
      }
    }
    for (final j in Joint.values) {
      final p = point(j);
      if (p != null) {
        canvas.drawCircle(p, strokeWidth * 1.2, dot);
      }
    }
  }

  PoseFrame? _nearestFrame(int ms) {
    if (frames.isEmpty) return null;
    var lo = 0;
    var hi = frames.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (frames[mid].timestampMs < ms) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    // pick closer of lo and lo-1
    if (lo > 0) {
      final a = frames[lo - 1];
      final b = frames[lo];
      if ((ms - a.timestampMs).abs() < (b.timestampMs - ms).abs()) {
        return a;
      }
    }
    return frames[lo];
  }

  @override
  bool shouldRepaint(covariant SkeletonOverlay oldDelegate) {
    return oldDelegate.positionMs != positionMs ||
        oldDelegate.frames != frames;
  }
}
