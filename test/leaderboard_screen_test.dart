import 'package:ag_battle_zone/features/home/screens/leaderboard_screen.dart';
import 'package:ag_battle_zone/features/home/services/leaderboard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows leaderboard entries from injected stream', (tester) async {
    final stream = Stream<List<LeaderboardEntry>>.value([
      const LeaderboardEntry(
        uid: '1',
        displayName: 'Ali',
        totalCoins: 1200,
        winningBalance: 300,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(home: LeaderboardScreen(leaderboardStream: stream)),
    );

    await tester.pump();

    expect(find.text('Top Leaderboard'), findsOneWidget);
    expect(find.text('Ali'), findsWidgets);
    expect(find.textContaining('coins'), findsWidgets);
  });
}
