import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golfbuddy/app.dart';

void main() {
  testWidgets('renders 3-tab bottom nav', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GolfBuddyApp()));
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Capture'), findsWidgets);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
