import 'package:ag_battle_zone/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Login screen shows branding and legal agreement text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('AG Battle Zone'), findsOneWidget);
    expect(find.textContaining('Terms & Conditions'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
