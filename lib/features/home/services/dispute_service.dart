import 'package:cloud_firestore/cloud_firestore.dart';

class DisputeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get disputes =>
      _firestore.collection('disputes');

  Stream<QuerySnapshot<Map<String, dynamic>>> streamPendingDisputes() {
    return disputes.where('status', isEqualTo: 'pending').snapshots();
  }

  Future<void> resolveDispute(String disputeId, String action) async {
    await disputes.doc(disputeId).update({
      'status': action == 'cancel' ? 'cancelled' : 'dismissed',
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': 'admin',
    });
  }

  Future<void> createDispute(Map<String, dynamic> data) async {
    await disputes.add(data);
  }
}
