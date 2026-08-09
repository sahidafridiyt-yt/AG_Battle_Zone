import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Firebase initialization timed out. Check your Firebase config or network connection.');
      },
    );
  } on TimeoutException catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Firebase init timed out: $error');
      debugPrint('$stackTrace');
    }
    rethrow;
  } on FirebaseException catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Firebase init failed: ${error.message}');
      debugPrint('$stackTrace');
    }
    rethrow;
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Firebase init failed: $error');
      debugPrint('$stackTrace');
    }
    rethrow;
  }
}
