import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'task_model.dart';

class TaskSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Update task stats when a session completes
  Future<void> updateTaskStats({
    required String taskId,
    required Duration sessionDuration,
    required String sessionType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final taskRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .doc(taskId);

      // Only update stats for focus sessions
      if (sessionType != 'focus') return;

      final sessionMinutes = sessionDuration.inMinutes;

      await _firestore.runTransaction((transaction) async {
        final taskDoc = await transaction.get(taskRef);

        if (!taskDoc.exists) {
          debugPrint('Task $taskId not found, skipping stats update');
          return;
        }

        final currentData = taskDoc.data()!;
        final currentPomodoros = currentData['pomodorosDone'] as int? ?? 0;
        final currentMinutes = currentData['minutesLogged'] as int? ?? 0;
        final requiredPomodoros = currentData['pomodorosRequired'] as int? ?? 1;

        final nextPomodoros = currentPomodoros + 1;
        final nextMinutes = currentMinutes + sessionMinutes;
        final shouldComplete = nextPomodoros >= requiredPomodoros;

        transaction.update(taskRef, {
          'pomodorosDone': nextPomodoros,
          'minutesLogged': nextMinutes,
          'completed': shouldComplete,
        });

        debugPrint(
          'Updated task $taskId: +1 pomodoro, +$sessionMinutes minutes, completed=$shouldComplete (required=$requiredPomodoros)',
        );
      });
    } catch (e) {
      debugPrint('Error updating task stats: $e');
    }
  }

  // Get task by topic name (for session completion)
  Future<Task?> getTaskByTopicName(String topicName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .where('title', isEqualTo: topicName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return Task.fromJson(doc.data(), doc.id);
    } catch (e) {
      debugPrint('Error getting task by topic name: $e');
      return null;
    }
  }

  // Update task stats when session completes
  Future<void> onSessionComplete({
    required String? topicId,
    required Duration sessionDuration,
    required String sessionType,
  }) async {
    if (topicId == null || !topicId.startsWith('task_')) return;

    // Extract task ID from topic id
    final taskId = topicId.replaceFirst('task_', '');

    await updateTaskStats(
      taskId: taskId,
      sessionDuration: sessionDuration,
      sessionType: sessionType,
    );
  }
}

