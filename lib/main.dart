import 'package:ag_battle_zone/app.dart';
import 'package:ag_battle_zone/config/env_config.dart';
import 'package:ag_battle_zone/firebase/firebase_initializer.dart';
import 'package:ag_battle_zone/features/auth/services/referral_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await EnvConfig.load();

  String? firebaseInitError;

  try {
    await initializeFirebase();
    // Native App Links / Universal Links are handled by platform-level intent.
    // We will rely on platform integration and the app's startup to receive the URI
    // (e.g., via a small native plugin or handle initial intent in MainActivity). If the
    // platform provides an incoming URI containing `ref` param, set it into ReferralService.
    // Implementation note: add native intent handling to MainActivity (Android) and
    // SceneDelegate/AppDelegate (iOS) to pass incoming link to Flutter via method channel
    // and then call `ReferralService.setPending(code)` on the Dart side.
  } catch (error) {
    firebaseInitError = error.toString();
    debugPrint('Firebase initialization failed: $firebaseInitError');
  }

  runApp(AgBattleZoneApp(firebaseInitError: firebaseInitError));
}
