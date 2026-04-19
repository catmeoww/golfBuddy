import 'package:flutter/widgets.dart';

// TODO: LLD §7 — CustomPainter drawing joint lines + dots, binary-search by timestamp.
class SkeletonOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // intentionally empty
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
