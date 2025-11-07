import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'session_model.dart';

class SessionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _userSessions(String uid) =>
      _firestore.collection('users').doc(uid).collection('sessions');

  Future<void> saveSession(SessionModel session) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final sessionData = session.toMap();
      // Remove the empty ID field since Firestore will generate it
      sessionData.remove('id');

      final docRef = await _userSessions(user.uid).add(sessionData);
      debugPrint('Session saved successfully with ID: ${docRef.id}');
    } catch (e) {
      debugPrint('Failed to save session: $e');
      rethrow;
    }
  }

  Stream<List<SessionModel>> watchUserSessions({
    DateTime? from,
    DateTime? to,
    int? limit,
  }) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    Query<Map<String, dynamic>> query = _userSessions(user.uid);

    if (from != null) {
      query = query.where(
        'endAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(from),
      );
    }
    if (to != null) {
      query = query.where('endAt', isLessThan: Timestamp.fromDate(to));
    }

    query = query.orderBy('endAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => SessionModel.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  Future<List<SessionModel>> getUserSessions({
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    Query<Map<String, dynamic>> query = _userSessions(user.uid);

    if (from != null) {
      query = query.where(
        'endAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(from),
      );
    }
    if (to != null) {
      query = query.where('endAt', isLessThan: Timestamp.fromDate(to));
    }

    query = query.orderBy('endAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => SessionModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
