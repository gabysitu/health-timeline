import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _entriesCollection {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('health_entries');
  }

  Stream<QuerySnapshot> getRecentEntries() {
    return _entriesCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<List<QueryDocumentSnapshot>> getTodayEntries() async {
    final now = DateTime.now();

    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final snapshot = await _entriesCollection
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .get();

    return snapshot.docs;
  }
}