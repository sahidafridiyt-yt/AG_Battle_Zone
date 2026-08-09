import 'package:ag_battle_zone/firebase/firebase_initializer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class TransactionService {
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;

  FirebaseAuth get auth => _auth ??= FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;

  Future<void> _ensureInitialized() async {
    if (Firebase.apps.isEmpty) {
      await initializeFirebase();
    }
  }

  Future<void> requestCoinUpdate({
    required String type,
    required int amount,
    String? note,
  }) async {
    await _ensureInitialized();
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated.');
    }

    await firestore.collection('transactions').add({
      'uid': uid,
      'type': type,
      'amount': amount,
      'note': note ?? '',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
