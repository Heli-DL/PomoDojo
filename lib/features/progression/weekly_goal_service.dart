import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class WeeklyGoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userSessions(String uid) =>
      _firestore.collection('users').doc(uid).collection('sessions');

  /// Get the start of the current week (Monday)
  DateTime getCurrentWeekStart() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final daysFromMonday = weekday == 7
        ? 0
        : weekday - 1; // Sunday = 7, Monday = 1
    return DateTime(now.year, now.month, now.day - daysFromMonday);
  }

  /// Get the end of the current week (Sunday)
  DateTime getCurrentWeekEnd() {
    final weekStart = getCurrentWeekStart();
    return weekStart.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );
  }

  /// Get completed sessions count for the current week
  Future<int> getCurrentWeekSessions(String uid) async {
    try {
      final weekStart = getCurrentWeekStart();
      final weekEnd = getCurrentWeekEnd();

      debugPrint(
        'Weekly Goal - Querying sessions for week: ${weekStart.toIso8601String()} to ${weekEnd.toIso8601String()}',
      );

      // Query by date range only (avoids composite index requirement)
      // Then filter by sessionType in memory (same approach as stream)
      final querySnapshot = await _userSessions(uid)
          .where('endAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .where('endAt', isLessThanOrEqualTo: Timestamp.fromDate(weekEnd))
          .get();

      // Filter to only focus sessions in memory
      final focusSessions = querySnapshot.docs
          .where((doc) => doc.data()['sessionType'] == 'focus')
          .length;

      debugPrint(
        'Weekly Goal - Found $focusSessions focus sessions this week (from ${querySnapshot.docs.length} total sessions)',
      );

      // Debug: Print details of each focus session found
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['sessionType'] == 'focus') {
          debugPrint(
            'Weekly Goal - Focus Session: ${data['sessionType']} at ${data['endAt']}',
          );
        }
      }

      return focusSessions;
    } catch (e) {
      debugPrint('Error getting current week sessions: $e');
      return 0;
    }
  }

  /// Get weekly goal progress data
  Future<WeeklyGoalProgress> getWeeklyGoalProgress(
    String uid,
    int weeklyGoal,
  ) async {
    try {
      final currentSessions = await getCurrentWeekSessions(uid);
      final progress = weeklyGoal > 0
          ? (currentSessions / weeklyGoal).clamp(0.0, 1.0)
          : 0.0;
      final remaining = (weeklyGoal - currentSessions).clamp(0, weeklyGoal);

      return WeeklyGoalProgress(
        currentSessions: currentSessions,
        weeklyGoal: weeklyGoal,
        progress: progress,
        remaining: remaining,
        weekStart: getCurrentWeekStart(),
        weekEnd: getCurrentWeekEnd(),
      );
    } catch (e) {
      debugPrint('Error getting weekly goal progress: $e');
      return WeeklyGoalProgress(
        currentSessions: 0,
        weeklyGoal: weeklyGoal,
        progress: 0.0,
        remaining: weeklyGoal,
        weekStart: getCurrentWeekStart(),
        weekEnd: getCurrentWeekEnd(),
      );
    }
  }

  /// Stream weekly goal progress
  Stream<WeeklyGoalProgress> streamWeeklyGoalProgress(
    String uid,
    int weeklyGoal,
  ) {
    final weekStart = getCurrentWeekStart();
    final weekEnd = getCurrentWeekEnd();

    debugPrint(
      'Weekly Goal Stream - Querying sessions from ${weekStart.toIso8601String()} to ${weekEnd.toIso8601String()}',
    );

    return _userSessions(uid)
        .where('endAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .where('endAt', isLessThanOrEqualTo: Timestamp.fromDate(weekEnd))
        .snapshots()
        .map((snapshot) {
          // Filter to only focus sessions in memory
          final focusSessions = snapshot.docs
              .where((doc) => doc.data()['sessionType'] == 'focus')
              .length;

          final progress = weeklyGoal > 0
              ? (focusSessions / weeklyGoal).clamp(0.0, 1.0)
              : 0.0;
          final remaining = (weeklyGoal - focusSessions).clamp(0, weeklyGoal);

          debugPrint(
            'Weekly Goal Stream - Found $focusSessions focus sessions this week (Goal: $weeklyGoal, Progress: ${(progress * 100).toStringAsFixed(0)}%)',
          );

          return WeeklyGoalProgress(
            currentSessions: focusSessions,
            weeklyGoal: weeklyGoal,
            progress: progress,
            remaining: remaining,
            weekStart: weekStart,
            weekEnd: weekEnd,
          );
        })
        .handleError((error) {
          debugPrint('Weekly Goal Stream Error: $error');
          return WeeklyGoalProgress(
            currentSessions: 0,
            weeklyGoal: weeklyGoal,
            progress: 0.0,
            remaining: weeklyGoal,
            weekStart: weekStart,
            weekEnd: weekEnd,
          );
        });
  }
}

class WeeklyGoalProgress {
  final int currentSessions;
  final int weeklyGoal;
  final double progress; // 0.0 to 1.0
  final int remaining;
  final DateTime weekStart;
  final DateTime weekEnd;

  const WeeklyGoalProgress({
    required this.currentSessions,
    required this.weeklyGoal,
    required this.progress,
    required this.remaining,
    required this.weekStart,
    required this.weekEnd,
  });

  bool get isCompleted => currentSessions >= weeklyGoal;
  bool get isOnTrack => progress >= 0.7; // 70% or more progress
  String get progressText => '$currentSessions / $weeklyGoal';
  String get remainingText => '$remaining remaining';
}
