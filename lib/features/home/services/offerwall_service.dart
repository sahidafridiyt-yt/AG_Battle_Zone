import 'package:cloud_firestore/cloud_firestore.dart';

class OfferwallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get logs =>
      _firestore.collection('offerwall_logs');

  Stream<QuerySnapshot<Map<String, dynamic>>> streamLogs() {
    return logs.orderBy('timestamp', descending: true).snapshots();
  }
}
