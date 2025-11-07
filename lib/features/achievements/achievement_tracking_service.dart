import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service to track achievement-related metrics that require additional tracking
/// beyond basic user stats
class AchievementTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userTrackingDoc(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('tracking')
          .doc('achievements');

  /// Track a task completion. Increments a lifetime count only once per task id.
  Future<void> trackTaskCompleted({
    required String uid,
    required String taskId,
  }) async {
    try {
      final docRef = _userTrackingDoc(uid);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        final data = doc.data() ?? {};
        final Map<String, bool> completedTaskIds = Map<String, bool>.from(
          data['completedTaskIds'] ?? {},
        );

        // Only count once per unique task id
        if (completedTaskIds[taskId] == true) {
          return;
        }

        final int currentCount = (data['completedTasksCount'] as int? ?? 0) + 1;
        completedTaskIds[taskId] = true;

        transaction.set(docRef, {
          ...data,
          'completedTasksCount': currentCount,
          'completedTaskIds': completedTaskIds,
          'lastTaskCompletedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      // Tracked task completed
    } catch (e) {
      debugPrint('Error tracking task completion: $e');
    }
  }

  /// Get lifetime completed tasks count
  Future<int> getCompletedTasksCount(String uid) async {
    try {
      final doc = await _userTrackingDoc(uid).get();
      if (!doc.exists) return 0;
      return doc.data()?['completedTasksCount'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error getting completed tasks count: $e');
      return 0;
    }
  }

  /// One-time backfill: populate completed tasks tracking from tasks collection
  Future<void> backfillCompletedTasksFromTasksCollection(String uid) async {
    try {
      final tasksQuery = await _firestore
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .where('completed', isEqualTo: true)
          .get();

      final Map<String, bool> completedTaskIds = {
        for (final doc in tasksQuery.docs) doc.id: true,
      };
      final count = completedTaskIds.length;

      final docRef = _userTrackingDoc(uid);
      await docRef.set({
        'completedTasksCount': count,
        'completedTaskIds': completedTaskIds,
        'lastTaskCompletedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Backfilled completed tasks
    } catch (e) {
      debugPrint('Error backfilling completed tasks: $e');
    }
  }

  /// Track break compliance - check if all scheduled breaks were taken
  Future<void> trackBreakCompliance({
    required String uid,
    required DateTime date,
    required bool tookBreak,
  }) async {
    try {
      final dateKey = _getDateKey(date);
      final docRef = _userTrackingDoc(uid);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        final data = doc.data() ?? {};
        final breakCompliance = Map<String, dynamic>.from(
          data['breakCompliance'] ?? {},
        );
        breakCompliance[dateKey] = tookBreak;

        transaction.set(docRef, {
          ...data,
          'breakCompliance': breakCompliance,
        }, SetOptions(merge: true));
      });

      // Tracked break compliance
    } catch (e) {
      debugPrint('Error tracking break compliance: $e');
    }
  }

  /// Get break compliance streak for the past N days
  Future<int> getBreakComplianceStreak(String uid, int days) async {
    try {
      final doc = await _userTrackingDoc(uid).get();
      if (!doc.exists) return 0;

      final data = doc.data() ?? {};
      final breakCompliance = Map<String, bool>.from(
        data['breakCompliance'] ?? {},
      );

      int streak = 0;
      final now = DateTime.now();
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey = _getDateKey(date);
        if (breakCompliance[dateKey] == true) {
          streak++;
        } else {
          break; // Streak broken
        }
      }

      return streak;
    } catch (e) {
      debugPrint('Error getting break compliance streak: $e');
      return 0;
    }
  }

  /// Track DND usage during a session
  Future<void> trackDNDUsage({
    required String uid,
    required DateTime date,
    required bool usedDND,
  }) async {
    try {
      final dateKey = _getDateKey(date);
      final docRef = _userTrackingDoc(uid);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        final data = doc.data() ?? {};
        final dndUsage = Map<String, dynamic>.from(data['dndUsage'] ?? {});
        // Store as set of dates when DND was used
        if (usedDND) {
          dndUsage[dateKey] = true;
        }

        transaction.set(docRef, {
          ...data,
          'dndUsage': dndUsage,
        }, SetOptions(merge: true));
      });

      // Tracked DND usage
    } catch (e) {
      debugPrint('Error tracking DND usage: $e');
    }
  }

  /// Get DND compliance streak (days when DND was used)
  Future<int> getDNDComplianceStreak(String uid, int days) async {
    try {
      final doc = await _userTrackingDoc(uid).get();
      if (!doc.exists) return 0;

      final data = doc.data() ?? {};
      final dndUsage = Map<String, bool>.from(data['dndUsage'] ?? {});

      int streak = 0;
      final now = DateTime.now();
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey = _getDateKey(date);
        if (dndUsage[dateKey] == true) {
          streak++;
        } else {
          break; // Streak broken
        }
      }

      return streak;
    } catch (e) {
      debugPrint('Error getting DND compliance streak: $e');
      return 0;
    }
  }

  /// Track task planning (tasks added before starting day)
  Future<void> trackTaskPlanning({
    required String uid,
    required DateTime date,
    required int tasksAdded,
  }) async {
    try {
      final dateKey = _getDateKey(date);
      final docRef = _userTrackingDoc(uid);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        final data = doc.data() ?? {};
        final taskPlanning = Map<String, int>.from(data['taskPlanning'] ?? {});
        taskPlanning[dateKey] = (taskPlanning[dateKey] ?? 0) + tasksAdded;

        transaction.set(docRef, {
          ...data,
          'taskPlanning': taskPlanning,
        }, SetOptions(merge: true));
      });

      // Tracked task planning
    } catch (e) {
      debugPrint('Error tracking task planning: $e');
    }
  }

  /// Get tasks added on a specific date
  Future<int> getTasksAddedOnDate(String uid, DateTime date) async {
    try {
      final doc = await _userTrackingDoc(uid).get();
      if (!doc.exists) return 0;

      final data = doc.data() ?? {};
      final taskPlanning = Map<String, int>.from(data['taskPlanning'] ?? {});
      final dateKey = _getDateKey(date);

      return taskPlanning[dateKey] ?? 0;
    } catch (e) {
      debugPrint('Error getting tasks added on date: $e');
      return 0;
    }
  }

  /// Track custom duration usage
  Future<void> trackCustomDurationUsage(String uid) async {
    try {
      final docRef = _userTrackingDoc(uid);
      await docRef.set({
        'customDurationUsed': true,
        'customDurationUsedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Tracked custom duration usage
    } catch (e) {
      debugPrint('Error tracking custom duration usage: $e');
    }
  }

  /// Check if custom duration has been used
  Future<bool> hasCustomDurationBeenUsed(String uid) async {
    try {
      final doc = await _userTrackingDoc(uid).get();
      if (!doc.exists) return false;

      return doc.data()?['customDurationUsed'] == true;
    } catch (e) {
      debugPrint('Error checking custom duration usage: $e');
      return false;
    }
  }

  /// Track stats viewing
  Future<void> trackStatsViewing(String uid) async {
    try {
      final docRef = _userTrackingDoc(uid);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        final data = doc.data() ?? {};
        final statsViewCount = (data['statsViewCount'] as int? ?? 0) + 1;

        transaction.set(docRef, {
          ...data,
          'statsViewCount': statsViewCount,
          'lastStatsView': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      // Tracked stats viewing
    } catch (e) {
      debugPrint('Error tracking stats viewing: $e');
    }
  }

  /// Get stats view count
  Future<int> getStatsViewCount(String uid) async {
    try {
      final doc = await _userTrackingDoc(uid).get();
      if (!doc.exists) return 0;

      return doc.data()?['statsViewCount'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error getting stats view count: $e');
      return 0;
    }
  }

  /// Track weekly goal completion
  Future<void> trackWeeklyGoalCompletion({
    required String uid,
    required DateTime weekStart,
    required bool completed,
  }) async {
    try {
      final weekKey = _getWeekKey(weekStart);
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('tracking')
          .doc('weeklyGoals');

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        final data = doc.data() ?? {};
        final completions = Map<String, bool>.from(data['completions'] ?? {});
        completions[weekKey] = completed;

        // Calculate streak
        final streak = _calculateWeeklyGoalStreak(completions);

        transaction.set(docRef, {
          ...data,
          'completions': completions,
          'currentStreak': streak,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      debugPrint(
        'Tracked weekly goal completion for week $weekKey: $completed',
      );
    } catch (e) {
      debugPrint('Error tracking weekly goal completion: $e');
    }
  }

  /// Get weekly goal streak
  Future<int> getWeeklyGoalStreak(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('tracking')
          .doc('weeklyGoals')
          .get();
      if (!doc.exists) return 0;

      final data = doc.data() ?? {};
      return data['currentStreak'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error getting weekly goal streak: $e');
      return 0;
    }
  }

  /// Get weekly goal completions map
  Future<Map<String, bool>> getWeeklyGoalCompletions(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('tracking')
          .doc('weeklyGoals')
          .get();
      if (!doc.exists) return {};

      final data = doc.data() ?? {};
      return Map<String, bool>.from(data['completions'] ?? {});
    } catch (e) {
      debugPrint('Error getting weekly goal completions: $e');
      return {};
    }
  }

  /// Calculate weekly goal streak from completions map
  int _calculateWeeklyGoalStreak(Map<String, bool> completions) {
    if (completions.isEmpty) return 0;

    // Sort weeks in descending order
    final sortedWeeks = completions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    final now = DateTime.now();
    final currentWeekStart = _getCurrentWeekStart(now);

    // Check if current week is completed
    final currentWeekKey = _getWeekKey(currentWeekStart);
    int weekOffset = completions[currentWeekKey] == true ? 0 : 1;

    // Count consecutive completed weeks
    for (int i = weekOffset; i < sortedWeeks.length; i++) {
      final weekKey = sortedWeeks[i];
      if (completions[weekKey] == true) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Get current week start (Monday)
  DateTime _getCurrentWeekStart(DateTime date) {
    final weekday = date.weekday;
    final daysFromMonday = weekday == 7 ? 0 : weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// Get date key (YYYY-MM-DD)
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get week key (YYYY-WW)
  String _getWeekKey(DateTime weekStart) {
    final week = _getWeekNumber(weekStart);
    return '${weekStart.year}-W${week.toString().padLeft(2, '0')}';
  }

  /// Get ISO week number
  int _getWeekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final weekNumber = ((dayOfYear - date.weekday + 10) / 7).floor();
    return weekNumber;
  }

  /// Get all tracking data for achievements
  Future<Map<String, dynamic>> getAllTrackingData(String uid) async {
    try {
      final achievementsDoc = await _userTrackingDoc(uid).get();
      final weeklyGoalsDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('tracking')
          .doc('weeklyGoals')
          .get();

      return {
        'breakCompliance': achievementsDoc.data()?['breakCompliance'] ?? {},
        'dndUsage': achievementsDoc.data()?['dndUsage'] ?? {},
        'taskPlanning': achievementsDoc.data()?['taskPlanning'] ?? {},
        'completedTasksCount':
            achievementsDoc.data()?['completedTasksCount'] ?? 0,
        'customDurationUsed':
            achievementsDoc.data()?['customDurationUsed'] ?? false,
        'statsViewCount': achievementsDoc.data()?['statsViewCount'] ?? 0,
        'weeklyGoalStreak': weeklyGoalsDoc.data()?['currentStreak'] ?? 0,
        'weeklyGoalCompletions': weeklyGoalsDoc.data()?['completions'] ?? {},
      };
    } catch (e) {
      debugPrint('Error getting all tracking data: $e');
      return {};
    }
  }
}
