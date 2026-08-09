# Step 1: Project Setup — AG Battle Zone

## Completed in Code

- [x] Flutter project: `ag_battle_zone` (`com.agbattlezone`)
- [x] Packages: firebase_core, firebase_auth, cloud_firestore, cloud_functions,
  google_mobile_ads, webview_flutter, url_launcher, carousel_slider, flutter_dotenv,
  provider, cached_network_image, intl
- [x] Security: `.gitignore` for secrets, `.env.example`, Firebase ownership docs
- [x] Folder structure: `lib/config`, `lib/core`, `lib/firebase`, `assets/`

## Owner Actions Required (Afridi)

### A. Firebase Project
1. Create Firebase project at https://console.firebase.google.com
2. Keep **Owner** role only on your account
3. Add developers with **Editor** role only

### B. FlutterFire CLI (on your machine)
```bash
cd e:\AG_Battle_Zone
dart pub global activate flutterfire_cli
flutterfire configure
```
Select your Firebase project and platforms (Android, iOS, Web).

### C. Environment File
```bash
copy .env.example .env
```
Edit `.env` with your AdMob IDs when ready.

### D. Verify Setup
```bash
flutter pub get
flutter analyze
flutter run
```

## Package Reference

| Package | Purpose |
|---------|---------|
| firebase_core | Firebase initialization |
| firebase_auth | User login/signup |
| cloud_firestore | Database |
| cloud_functions | Backend logic |
| google_mobile_ads | AdMob ads |
| webview_flutter | In-app web pages |
| url_launcher | Open external links |
| carousel_slider | Banner/slider UI |
| flutter_dotenv | Secure env vars |
| provider | State management |
| cached_network_image | Image caching |
| intl | Date/number formatting |

## Next Step

Proceed to **Step 2** of the roadmap when ready.
