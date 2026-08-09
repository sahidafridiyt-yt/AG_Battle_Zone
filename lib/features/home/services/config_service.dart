import 'package:cloud_firestore/cloud_firestore.dart';

class ConfigService {
  FirebaseFirestore? _firestore;
  FirebaseFirestore get _db => _firestore ??= FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get configDoc =>
      _db.collection('global_config').doc('config');

  Stream<Map<String, dynamic>> streamConfig() {
    return configDoc.snapshots().map((snapshot) => snapshot.data() ?? {});
  }

  Future<void> ensureDefaults() async {
    final doc = await configDoc.get();
    if (!doc.exists) {
      await configDoc.set({
        'min_withdrawal_limit': 100,
        'ads_status': true,
        'game_status': true,
        'active_sdk': 'none',
        'referral_bonus_amount': 5,
        'video_cooldown_seconds': 30,
        'max_daily_videos': 5,
        'lockdown_enabled': false,
      });
    }
  }

  Future<void> updateConfig(Map<String, dynamic> data) async {
    await configDoc.set(data, SetOptions(merge: true));
  }

  Future<void> setLockdown(bool enabled) async {
    await configDoc.set({'lockdown_enabled': enabled}, SetOptions(merge: true));
  }
}
