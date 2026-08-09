Hindi explanation (developer guidance):

1) Maksad:
- Client-side se `total_coins` aur `winning_balance` ko modify karne ki ijazat na dena. Sab coin updates sirf backend (Cloud Functions) ke through honge.

2) Approach:
- Firestore rules me `users` document par strict checks rakhe gaye hain:
  - `create` tabhi allow hoga jab `request.auth.uid == userId` aur initial coin fields `0` hon.
  - `update` allowed hai lekin woh update coin fields ko change nahi kar sakta: `total_coins` aur `winning_balance` must remain equal to server values.
  - `transactions` collection me client ek request create karega; Cloud Function ise process karega.

3) Deployment steps:
- Install Firebase CLI and login:

```bash
npm install -g firebase-tools
firebase login
```

- Initialize functions (agar pehle se nahi):

```bash
cd e:/AG_Battle_Zone
firebase init functions firestore
```

- Firestore rules deploy:

```bash
firebase deploy --only firestore:rules
```

- Functions deploy (Node.js):

```bash
cd functions
npm install
firebase deploy --only functions:processTransaction
```

4) Testing locally:
- Use Firebase emulator for testing rules and functions together.

```bash
firebase emulators:start --only firestore,functions
```

5) Notes:
- Cloud Functions use Admin SDK which bypasses security rules — isliye functions ko hi coin updates karne chahiye.
- Maintain an audit trail in `transactions` collection and mark `status` = 'processed'/'failed'.
- For extra safety, validate transaction requests server-side (user ownership, rate-limits, anti-fraud checks).
