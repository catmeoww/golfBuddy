import 'package:flutter/material.dart';

// TODO: LLD §3 — wire CaptureController state machine + camera preview.
class CaptureScreen extends StatelessWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Camera preview + record button will live here.\n\n'
            'Wired in a later milestone.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
