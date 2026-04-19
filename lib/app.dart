import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/bootstrap.dart';
import 'features/capture/capture_screen.dart';
import 'features/library/library_screen.dart';
import 'features/session_detail/session_detail_screen.dart';
import 'features/settings/players_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/storage_screen.dart';
import 'features/tournaments/tournaments_screen.dart';

// Three top-level branches per UX IA (Library default, Capture, Settings).
final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/library',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _RootShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (_, __) => const LibraryScreen(),
                routes: [
                  GoRoute(
                    path: 'sessions/:id',
                    builder: (_, state) => SessionDetailScreen(
                      sessionId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'tournaments',
                    builder: (_, __) => const TournamentsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/capture',
                builder: (_, __) => const CaptureScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'players',
                    builder: (_, __) => const PlayersScreen(),
                  ),
                  GoRoute(
                    path: 'tournaments',
                    builder: (_, __) => const TournamentsScreen(),
                  ),
                  GoRoute(
                    path: 'storage',
                    builder: (_, __) => const StorageScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class GolfBuddyApp extends ConsumerWidget {
  const GolfBuddyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(bootstrapProvider);
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'GolfBuddy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

class _RootShell extends StatelessWidget {
  const _RootShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam),
            label: 'Capture',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
