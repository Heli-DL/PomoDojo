import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'task_model.dart';
import '../achievements/achievement_tracking_service.dart';

// Cache for tasks to reduce database queries
final Map<String, List<Task>> _tasksCache = {};
final Map<String, DateTime> _cacheTimestamps = {};
const Duration _cacheExpiration = Duration(minutes: 5);

class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of tasks with optional filtering and caching
  Stream<List<Task>> watchTasks({
    bool? completed,
    String? priority,
    String? tag,
  }) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    final cacheKey =
        '${currentUser.uid}_${completed ?? 'null'}_${priority ?? 'null'}_${tag ?? 'null'}';

    // Check cache first
    if (_tasksCache.containsKey(cacheKey) &&
        _cacheTimestamps.containsKey(cacheKey)) {
      final cacheTime = _cacheTimestamps[cacheKey]!;
      if (DateTime.now().difference(cacheTime) < _cacheExpiration) {
        return Stream.value(_tasksCache[cacheKey]!);
      }
    }

    try {
      Query query = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('tasks');

      // Apply filters
      if (completed != null) {
        query = query.where('completed', isEqualTo: completed);
      }
      if (priority != null) {
        query = query.where('priority', isEqualTo: priority);
      }
      if (tag != null) {
        query = query.where('tags', arrayContains: tag);
      }

      return query
          .snapshots()
          .map((snapshot) {
            final tasks = snapshot.docs
                .map((doc) {
                  try {
                    return Task.fromJson(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );
                  } catch (e) {
                    debugPrint('TaskRepository: Error parsing task: $e');
                    return null;
                  }
                })
                .where((task) => task != null)
                .cast<Task>()
                .toList();

            // Sort by createdAt in descending order (newest first)
            tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            // Update cache
            _tasksCache[cacheKey] = tasks;
            _cacheTimestamps[cacheKey] = DateTime.now();

            return tasks;
          })
          .handleError((error) {
            debugPrint('TaskRepository: Error watching tasks: $error');
            return <Task>[];
          });
    } catch (e) {
      debugPrint('TaskRepository: Exception in watchTasks: $e');
      return Stream.value([]);
    }
  }

  // Clear cache for a user
  void _clearUserCache(String uid) {
    _tasksCache.removeWhere((key, value) => key.startsWith('${uid}_'));
    _cacheTimestamps.removeWhere((key, value) => key.startsWith('${uid}_'));
  }

  Future<void> add(Task draft) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final taskData = draft.toJson();
    taskData['createdAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('tasks')
        .add(taskData);

    // Clear cache after adding task
    _clearUserCache(currentUser.uid);
  }

  // Update an existing task
  Future<void> update(Task task) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('tasks')
        .doc(task.id)
        .update(task.toJson());

    // Clear cache after updating task
    _clearUserCache(currentUser.uid);
  }

  // Toggle task completion status
  Future<void> toggleComplete(String id, bool value) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final taskRef = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('tasks')
        .doc(id);

    // Use a transaction to read previous state and update
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(taskRef);
      if (!snapshot.exists) {
        throw Exception('Task not found');
      }
      transaction.update(taskRef, {'completed': value});

      // Tracking is handled after the transaction completes
    });

    // After transaction, if we transitioned to completed, record tracking once
    try {
      final doc = await taskRef.get();
      final completed = doc.data()?['completed'] as bool? ?? false;
      if (completed) {
        final tracking = AchievementTrackingService();
        await tracking.trackTaskCompleted(uid: currentUser.uid, taskId: id);
      }
    } catch (e) {
      debugPrint('TaskRepository: Error tracking task completion: $e');
    }

    // Clear cache after toggling completion
    _clearUserCache(currentUser.uid);
  }

  // Delete a task
  Future<void> delete(String id) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('tasks')
        .doc(id)
        .delete();

    // Clear cache after deleting task
    _clearUserCache(currentUser.uid);
  }

  // Increment task stats when a session completes
  Future<void> incrementStats(String id, {required int minutes}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final taskRef = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('tasks')
        .doc(id);

    await _firestore.runTransaction((transaction) async {
      final taskDoc = await transaction.get(taskRef);
      if (!taskDoc.exists) {
        throw Exception('Task not found');
      }

      final currentData = taskDoc.data()!;
      final currentPomodoros = currentData['pomodorosDone'] as int? ?? 0;
      final currentMinutes = currentData['minutesLogged'] as int? ?? 0;

      transaction.update(taskRef, {
        'pomodorosDone': currentPomodoros + 1,
        'minutesLogged': currentMinutes + minutes,
      });
    });
  }

  // Get a single task by ID
  Future<Task?> getTask(String id) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return null;
    }

    final doc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('tasks')
        .doc(id)
        .get();

    if (!doc.exists) {
      return null;
    }

    return Task.fromJson(doc.data()!, doc.id);
  }
}
