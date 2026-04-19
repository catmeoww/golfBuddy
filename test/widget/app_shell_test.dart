import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golfbuddy/app.dart';
import 'package:golfbuddy/core/di.dart';
import 'package:golfbuddy/data/db/database.dart';
import 'package:drift/native.dart';

void main() {
  testWidgets('renders Library/Capture/Settings bottom nav', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith(
            (ref) => AppDatabase.forTesting(NativeDatabase.memory()),
          ),
        ],
        child: const GolfBuddyApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Library'), findsWidgets);
    expect(find.text('Capture'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
