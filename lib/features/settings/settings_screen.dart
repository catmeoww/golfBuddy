import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Players'),
            onTap: () => context.go('/settings/players'),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('Tournaments'),
            onTap: () => context.go('/settings/tournaments'),
          ),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Storage'),
            onTap: () => context.go('/settings/storage'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: Text(version),
          ),
        ],
      ),
    );
  }
}
