import 'package:ag_battle_zone/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AG Battle Zone app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const AgBattleZoneApp());

    expect(find.text('AG Battle Zone'), findsOneWidget);
    expect(find.text('Log in to continue your journey.'), findsOneWidget);
  });
}
