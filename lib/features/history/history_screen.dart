import 'package:flutter/material.dart';

// TODO: LLD §6 — subscribe to SessionRepository stream, render list.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Past swings will appear here.\n\n'
            'Empty state, filter, and compare picker are TBD.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
