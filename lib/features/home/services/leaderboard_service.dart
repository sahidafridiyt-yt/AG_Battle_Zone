import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.totalCoins,
    required this.winningBalance,
  });

  final String uid;
  final String displayName;
  final int totalCoins;
  final int winningBalance;

  factory LeaderboardEntry.fromMap(String uid, Map<String, dynamic> data) {
    return LeaderboardEntry(
      uid: uid,
      displayName: (data['displayName'] ?? 'Player').toString(),
      totalCoins: (data['total_coins'] as num?)?.toInt() ?? 0,
      winningBalance: (data['winning_balance'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeaderboardService {
  FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ??= FirebaseFirestore.instance;

  Stream<List<LeaderboardEntry>> streamLeaderboard() {
    return _db
        .collection('users')
        .orderBy('total_coins', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeaderboardEntry.fromMap(doc.id, doc.data()))
            .toList());
  }
}
