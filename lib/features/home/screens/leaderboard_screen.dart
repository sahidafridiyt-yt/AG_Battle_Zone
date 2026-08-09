import 'package:ag_battle_zone/features/home/services/leaderboard_service.dart';
import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key, this.leaderboardStream});

  final Stream<List<LeaderboardEntry>>? leaderboardStream;

  @override
  Widget build(BuildContext context) {
    final service = LeaderboardService();
    final stream = leaderboardStream ?? service.streamLeaderboard();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Top Leaderboard'),
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<LeaderboardEntry>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load leaderboard right now.', style: TextStyle(color: Colors.white70)),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data ?? const <LeaderboardEntry>[];
          if (entries.isEmpty) {
            return const Center(
              child: Text('No leaderboard data yet.', style: TextStyle(color: Colors.white70)),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TopThreeCard(entries: entries),
              const SizedBox(height: 16),
              ...entries.asMap().entries.map((entry) {
                final index = entry.key;
                final player = entry.value;
                final isTopThree = index < 3;
                return Card(
                  color: const Color(0xFF111827),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isTopThree ? Colors.amberAccent : Colors.white24,
                      child: Text('${index + 1}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(
                      player.displayName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${player.totalCoins} coins • Win balance: ${player.winningBalance}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: isTopThree
                        ? const Icon(Icons.emoji_events_rounded, color: Colors.amberAccent)
                        : const Icon(Icons.military_tech_rounded, color: Colors.white54),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}

class _TopThreeCard extends StatelessWidget {
  const _TopThreeCard({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final topThree = entries.take(3).toList();
    if (topThree.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFF7C2D12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('Champion Board', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(topThree.length, (index) {
              final player = topThree[index];
              final badge = index == 0 ? '🥇' : index == 1 ? '🥈' : '🥉';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(badge, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 6),
                        Text(player.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text('${player.totalCoins} coins', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
