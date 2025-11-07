import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../timer/session_model.dart';

class StatsRepository {
  StatsRepository(this._db, this._auth);
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Query<Map<String, dynamic>> _sessionsCol({
    required DateTime from,
    required DateTime to,
  }) {
    final uid = _auth.currentUser!.uid;
    // Store timestamps in UTC in Firestore; compare with isEqualTo/where range on endAt.
    return _db
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .where(
          'endAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from.toUtc()),
        )
        .where('endAt', isLessThan: Timestamp.fromDate(to.toUtc()))
        .orderBy('endAt', descending: false);
  }

  Stream<List<Map<String, dynamic>>> watchSessions({
    required DateTime from,
    required DateTime to,
  }) {
    final user = _auth.currentUser;
    if (user == null) {
      // No authenticated user → return empty stream to avoid crashes
      return const Stream<List<Map<String, dynamic>>>.empty();
    }
    return _sessionsCol(
      from: from,
      to: to,
    ).snapshots().map((s) => s.docs.map((d) => d.data()).toList());
  }

  Stream<List<SessionModel>> watchSessionModels({
    required DateTime from,
    required DateTime to,
  }) {
    final user = _auth.currentUser;
    if (user == null) {
      // No authenticated user → return empty stream to avoid crashes
      return const Stream<List<SessionModel>>.empty();
    }
    return _sessionsCol(from: from, to: to).snapshots().map(
      (s) => s.docs.map((d) => SessionModel.fromMap(d.data(), d.id)).toList(),
    );
  }
}
