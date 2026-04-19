import 'package:flutter/material.dart';

// Legacy placeholder: the main analysis UI now lives in
// features/session_detail/session_detail_screen.dart where the video,
// skeleton overlay, phase scrubber, and metric cards are composed.
class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Open a session from the Library to analyze.')),
    );
  }
}
