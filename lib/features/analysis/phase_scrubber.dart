import 'package:flutter/material.dart';

import '../../domain/models/annotation.dart';
import '../../domain/models/phase.dart';
import '../../domain/models/swing_analysis.dart';

/// LLD §7/§8 — thin horizontal strip of A/T/I/F dots + annotation markers.
/// Tapping a phase dot seeks the video to that timestamp via [onSeek].
class PhaseScrubber extends StatelessWidget {
  const PhaseScrubber({
    required this.durationMs,
    required this.positionMs,
    required this.phases,
    required this.annotations,
    required this.onSeek,
    super.key,
  });

  final int durationMs;
  final int positionMs;
  final List<PhaseMarker> phases;
  final List<Annotation> annotations;
  final ValueChanged<int> onSeek;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onTapUp: (details) {
            if (durationMs <= 0) return;
            final rel = (details.localPosition.dx / width).clamp(0.0, 1.0);
            onSeek((rel * durationMs).round());
          },
          child: SizedBox(
            height: 36,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 2,
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                for (final a in annotations.where((a) => a.timestampMs != null))
                  _marker(
                    position: _relPos(a.timestampMs!, width),
                    color: theme.colorScheme.secondary,
                    icon: Icons.bookmark,
                    label: null,
                    onTap: () => onSeek(a.timestampMs!),
                  ),
                for (final p in phases)
                  _marker(
                    position: _relPos(p.timestampMs, width),
                    color: theme.colorScheme.primary,
                    icon: null,
                    label: _phaseLabel(p.phase),
                    onTap: () => onSeek(p.timestampMs),
                  ),
                // Playhead.
                Positioned(
                  left: _relPos(positionMs, width) - 1,
                  top: 4,
                  bottom: 4,
                  child: Container(
                    width: 2,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _relPos(int ms, double width) {
    if (durationMs <= 0) return 0.0;
    return (ms / durationMs).clamp(0.0, 1.0) * width;
  }

  Widget _marker({
    required double position,
    required Color color,
    IconData? icon,
    String? label,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: position - 10,
      top: 6,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 12)
              : Text(
                  label ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  static String _phaseLabel(SwingPhase p) {
    switch (p) {
      case SwingPhase.address:
        return 'A';
      case SwingPhase.top:
        return 'T';
      case SwingPhase.impact:
        return 'I';
      case SwingPhase.finish:
        return 'F';
    }
  }
}
