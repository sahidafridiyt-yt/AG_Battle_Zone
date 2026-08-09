const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();


// Trigger: when a user's `first_action_completed` flips false->true, credit the referrer.
exports.handleUserFirstAction = functions.firestore
  .document('users/{uid}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const uid = context.params.uid;

    if (!before || !after) return null;
    if (before.first_action_completed) return null;
    if (!after.first_action_completed) return null;

    const referredByUid = after.referred_by;
    if (!referredByUid) return null;
    if (after.referral_rewarded) return null;

    const userRef = db.collection('users').doc(uid);
    const referrerRef = db.collection('users').doc(referredByUid);
    // Match the app's ConfigService: collection 'global_config' doc 'config'
    const configRef = db.collection('global_config').doc('config');

    return db.runTransaction(async (tx) => {
      const [referrerSnap, configSnap, userSnap] = await Promise.all([
        tx.get(referrerRef),
        tx.get(configRef),
        tx.get(userRef),
      ]);

      if (!referrerSnap.exists) {
        console.log('Referrer not found:', referredByUid);
        return null;
      }

      const config = configSnap.exists ? configSnap.data() : {};
      const bonus = Number(config.referral_bonus_amount || 0);

      // Update referrer's wallet (adjust `coins` field name as per your schema)
      tx.update(referrerRef, {
        coins: admin.firestore.FieldValue.increment(bonus),
      });

      // Add a transaction entry for bookkeeping
      const txDoc = db.collection('transactions').doc();
      tx.set(txDoc, {
        user_id: referredByUid,
        type: 'referral_bonus',
        amount: bonus,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          referred_uid: uid,
        },
      });

      // Mark the referred user as rewarded so the trigger is idempotent
      tx.update(userRef, { referral_rewarded: true });

      return null;
    }).catch((err) => {
      console.error('Error crediting referrer:', err);
      throw err;
    });
  });
// When a transaction document is created (by client), this function validates
// and applies the coin update to the user's document using Firestore Admin SDK.
exports.processTransaction = functions.firestore
  .document('transactions/{txId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const txId = context.params.txId;

    if (!data) return null;

    const uid = data.uid;
    const type = data.type; // 'credit' or 'debit'
    const amount = data.amount;

    if (!uid || !type || !amount) {
      console.error('Invalid transaction data', txId, data);
      await snap.ref.update({ status: 'invalid', processedAt: admin.firestore.FieldValue.serverTimestamp() });
      return null;
    }

    const userRef = db.collection('users').doc(uid);

    try {
      await db.runTransaction(async (t) => {
        const userSnap = await t.get(userRef);
        if (!userSnap.exists) throw new Error('User not found: ' + uid);

        const currentTotal = (userSnap.get('total_coins') || 0);
        const currentWinning = (userSnap.get('winning_balance') || 0);

        let newTotal = currentTotal;
        let newWinning = currentWinning;

        if (type === 'credit') {
          newTotal = currentTotal + amount;
          newWinning = currentWinning + amount;
        } else if (type === 'debit') {
          newTotal = Math.max(0, currentTotal - amount);
          newWinning = Math.max(0, currentWinning - amount);
        } else {
          throw new Error('Unknown transaction type: ' + type);
        }

        t.update(userRef, { total_coins: newTotal, winning_balance: newWinning });
        t.update(snap.ref, { status: 'processed', processedAt: admin.firestore.FieldValue.serverTimestamp() });
      });

      console.log('Transaction processed', txId);
      return null;
    } catch (err) {
      console.error('Transaction processing failed', txId, err);
      await snap.ref.update({ status: 'failed', reason: String(err), processedAt: admin.firestore.FieldValue.serverTimestamp() });
      return null;
    }
  });
