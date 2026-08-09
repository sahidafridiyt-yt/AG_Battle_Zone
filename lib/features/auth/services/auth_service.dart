import 'dart:async';
import 'dart:math';

import 'package:ag_battle_zone/core/constants/app_constants.dart';
import 'package:ag_battle_zone/firebase/firebase_initializer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  FirebaseAuth get auth => _auth ??= FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;

  Future<void> _ensureInitialized() async {
    if (Firebase.apps.isEmpty) {
      await initializeFirebase();
    }
  }

  Future<T> _runWithTimeout<T>(Future<T> Function() action, {required String operationName}) async {
    try {
      return await action().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw Exception('$operationName timed out. Please check your internet connection or Firebase settings.');
    }
  }

  Future<UserCredential> signUp({required String email, required String password, String? displayName, String? referralCode}) async {
    await _ensureInitialized();
    return _runWithTimeout<UserCredential>(
      () async {
        final cred = await auth.createUserWithEmailAndPassword(email: email, password: password);
        final uid = cred.user!.uid;

        // Generate a unique referral code and create a minimal user document.
        final referralCode = _generateReferralCode(displayName ?? email.split('@').first, uid);

        // Security rules force coin fields to 0 on client create.
        await firestore.collection('users').doc(uid).set({
          'displayName': displayName ?? '',
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'total_coins': 0,
          'winning_balance': 0,
          'referral_code': referralCode,
          'referred_by': null,
          'referral_rewarded': false,
        });

        // If the new user supplied a referral code, resolve it to a referrer's uid and set `referred_by`.
        if (referralCode != null && referralCode.trim().isNotEmpty) {
          try {
            final query = await firestore
                .collection('users')
                .where('referral_code', isEqualTo: referralCode.trim().toUpperCase())
                .limit(1)
                .get();
            if (query.docs.isNotEmpty) {
              final referrerUid = query.docs.first.id;
              await firestore.collection('users').doc(uid).update({'referred_by': referrerUid});
            }
          } catch (e) {
            // Non-fatal: log and continue signup.
            // In production you may want to surface this to analytics.
            // ignore: avoid_print
            print('Referral resolution failed: $e');
          }
        }

        return cred;
      },
      operationName: 'Account creation',
    );
  }

  String _generateReferralCode(String source, String uid) {
    final raw = source.trim().toUpperCase();
    final alphaNum = raw.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final prefix = alphaNum.isEmpty ? 'USER' : alphaNum.substring(0, min(6, alphaNum.length));
    final suffix = uid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final codeSuffix = suffix.length <= 6 ? suffix : suffix.substring(0, 6);
    return '$prefix$codeSuffix';
  }

  Future<UserCredential> signIn({required String email, required String password}) async {
    await _ensureInitialized();
    return _runWithTimeout<UserCredential>(
      () => auth.signInWithEmailAndPassword(email: email, password: password),
      operationName: 'Login',
    );
  }

  Future<UserCredential> signInOrCreateAdmin({required String email, required String password}) async {
    await _ensureInitialized();

    try {
      return await _runWithTimeout<UserCredential>(
        () => auth.signInWithEmailAndPassword(email: email, password: password),
        operationName: 'Admin login',
      );
    } on FirebaseAuthException catch (error) {
      final normalizedEmail = email.trim().toLowerCase();
      final isAdminEmail = normalizedEmail == AppConstants.adminEmail.toLowerCase();

      if (error.code == 'user-not-found' && isAdminEmail) {
        return await signUp(email: email, password: password, displayName: 'Admin');
      }

      rethrow;
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await auth.signOut();
  }
}
