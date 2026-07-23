import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/health_entry.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _healthEntriesCollection {
    final userId = _currentUserId;

    if (userId == null) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('health_entries');
  }

  Stream<List<HealthEntry>> getRecentEntries({
    int limit = 20,
  }) {
    final collection = _healthEntriesCollection;

    if (collection == null) {
      return Stream.value([]);
    }

    return collection
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(HealthEntry.fromFirestore)
              .toList(),
        );
  }

  Future<List<HealthEntry>> getTodayEntries() async {
    final now = DateTime.now();

    final startOfToday = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final endOfToday = startOfToday.add(
      const Duration(days: 1),
    );

    return getEntriesBetween(
      startDate: startOfToday,
      endDate: endOfToday,
      endDateIsExclusive: true,
    );
  }

  Future<List<HealthEntry>> getEntriesBetween({
    required DateTime startDate,
    required DateTime endDate,
    bool endDateIsExclusive = false,
  }) async {
    final collection = _healthEntriesCollection;

    if (collection == null) {
      return [];
    }

    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final normalizedEnd = endDateIsExclusive
        ? endDate
        : DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
          ).add(const Duration(days: 1));

    final snapshot = await collection
        .where(
          'createdAt',
          isGreaterThanOrEqualTo:
              Timestamp.fromDate(normalizedStart),
        )
        .where(
          'createdAt',
          isLessThan: Timestamp.fromDate(normalizedEnd),
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .get();

    return snapshot.docs
        .map(HealthEntry.fromFirestore)
        .toList();
  }
}