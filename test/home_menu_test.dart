import 'package:ag_battle_zone/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Admin menu button appears for admin email', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(userEmail: 'sahidafridiyt@gmail.com', configStream: Stream.value({}))),
    );

    await tester.pumpAndSettle();

    expect(find.text('Admin Panel'), findsOneWidget);
  });

  testWidgets('Admin menu button stays hidden for non-admin email', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(userEmail: 'player@example.com', configStream: Stream.value({}))),
    );

    await tester.pumpAndSettle();

    expect(find.text('Admin Panel'), findsNothing);
  });
}
