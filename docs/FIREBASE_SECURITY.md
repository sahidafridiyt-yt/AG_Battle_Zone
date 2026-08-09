# Firebase Security & Ownership Policy — AG Battle Zone

## Owner vs Developer Access

| Role | Who | Firebase IAM Role | Can Do |
|------|-----|-------------------|--------|
| **Owner** | Afridi | **Owner** | Billing, delete project, manage IAM, all settings |
| **Developer** | Cursor AI / future devs | **Editor** only | Code, Firestore rules deploy*, Functions deploy* |

\* Deploy access can be restricted further via CI/CD with a service account if needed.

## Rules (Mandatory)

1. **Never grant Owner** to developers, contractors, or AI tools.
2. **Never grant Admin** unless absolutely required for billing setup.
3. New team members get **Editor** or **Viewer** only.
4. **Never hardcode** API keys, AdMob IDs, or secrets in source code.
5. Use `.env` for runtime secrets (AdMob). Use `flutterfire configure` for Firebase config.
6. Sensitive files are **gitignored** — see root `.gitignore`.

## Owner Setup Checklist (Afridi)

### 1. Create Firebase Project
- Go to [Firebase Console](https://console.firebase.google.com/)
- Create project: `ag-battle-zone` (or your chosen name)
- Enable: Authentication, Firestore, Cloud Functions

### 2. Add Developer with Editor Access
- Firebase Console → Project Settings → Users and permissions
- Add developer email → Role: **Editor** (NOT Owner)

### 3. Generate Local Config (Owner machine only)
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_PROJECT_ID
```
This creates (locally, not committed):
- `lib/firebase/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

### 4. Environment Variables
```bash
cp .env.example .env
# Fill AdMob and other keys in .env
```

### 5. AdMob Setup
- Create app in [AdMob Console](https://admob.google.com/)
- Put Ad Unit IDs in `.env` only

## What Gets Committed vs Not

| File | Git |
|------|-----|
| `.env.example` | ✅ Yes (template) |
| `.env` | ❌ No |
| `firebase_options.dart` | ❌ No |
| `google-services.json` | ❌ No |
| `GoogleService-Info.plist` | ❌ No |
| `firebase_options.dart.example` | ✅ Yes (reference) |

## Revoking Access

When a developer leaves:
1. Firebase Console → Users and permissions → Remove user
2. Rotate any shared service account keys
3. Review Firestore security rules
