import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'topic_model.dart';

class TopicRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _userTopics(String uid) =>
      _firestore.collection('users').doc(uid).collection('topics');

  Stream<List<Topic>> watchUserTopics() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(const []);
    return _userTopics(user.uid).snapshots().map(
      (s) => s.docs.map((d) => Topic.fromJson(d.data(), d.id)).toList(),
    );
  }

  Future<void> addTopic(Topic topic) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _userTopics(user.uid).add(topic.toJson());
  }

  Future<void> updateTopic(Topic topic) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _userTopics(user.uid).doc(topic.id).update(topic.toJson());
  }

  Future<void> deleteTopic(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _userTopics(user.uid).doc(id).delete();
  }
}
