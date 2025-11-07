import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../timer/session_model.dart';

class AchievementCalculator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Calculate current streak (consecutive days with at least one session)
  // Counts backwards from today, so if you have sessions yesterday but not today,
  // the streak is still 1 until tomorrow
  static Future<int> calculateCurrentStreak(String uid) async {
    try {
      final sessions = await _getUserSessions(uid);
      if (sessions.isEmpty) return 0;

      // Get unique dates that have sessions (focus sessions only)
      // Convert to local time to match with today's date
      final sessionDates = <DateTime>{};
      for (final session in sessions) {
        if (session.sessionType == 'focus') {
          // Convert UTC to local time
          final sessionLocal = session.startAt.toLocal();
          final sessionDate = DateTime(
            sessionLocal.year,
            sessionLocal.month,
            sessionLocal.day,
          );
          sessionDates.add(sessionDate);
        }
      }

      if (sessionDates.isEmpty) return 0;

      // Start from today and count backwards
      final todayLocal = DateTime.now();
      final todayDateOnly = DateTime(
        todayLocal.year,
        todayLocal.month,
        todayLocal.day,
      );

      int streak = 0;
      bool startedCounting = false;

      // Check up to 365 days back (reasonable limit)
      for (int i = 0; i < 365; i++) {
        final checkDate = todayDateOnly.subtract(Duration(days: i));

        // Check if this date has any sessions
        final hasSession = sessionDates.any((date) {
          return date.year == checkDate.year &&
              date.month == checkDate.month &&
              date.day == checkDate.day;
        });

        if (hasSession) {
          // This day has a session
          streak++;
          startedCounting = true;
        } else {
          // This day doesn't have a session
          if (i == 0) {
            // Today doesn't have a session - that's okay, skip today and continue from yesterday
            continue;
          } else {
            // A past day is missing - streak is broken
            // But only break if we've started counting (i.e., we found at least one day with a session)
            if (startedCounting) {
              break;
            } else {
              // Haven't found any sessions yet, keep looking
              continue;
            }
          }
        }
      }

      debugPrint(
        'Streak calculation: found ${sessionDates.length} unique session dates, calculated streak: $streak',
      );
      if (sessionDates.isNotEmpty) {
        final datesList = sessionDates.toList()..sort((a, b) => b.compareTo(a));
        debugPrint(
          'Recent session dates: ${datesList.take(5).map((d) => "${d.year}-${d.month}-${d.day}").join(", ")}',
        );
        debugPrint(
          'Today: ${todayDateOnly.year}-${todayDateOnly.month}-${todayDateOnly.day}',
        );
      }

      return streak;
    } catch (e) {
      debugPrint('Error calculating current streak: $e');
      return 0;
    }
  }

  // Calculate consecutive days with sessions
  static Future<int> calculateConsecutiveDays(String uid) async {
    return await calculateCurrentStreak(uid);
  }

  // Calculate consecutive sessions (sessions in a row without breaks)
  static Future<int> calculateConsecutiveSessions(String uid) async {
    try {
      final sessions = await _getUserSessions(uid);
      if (sessions.isEmpty) return 0;

      // Sort sessions by date (newest first)
      sessions.sort((a, b) => b.startAt.compareTo(a.startAt));

      int consecutiveSessions = 0;
      DateTime? lastSessionEndTime;

      for (final session in sessions) {
        // Calculate session end time (start + duration)
        final sessionEndTime = session.startAt.add(session.duration);

        if (lastSessionEndTime == null) {
          // First session (most recent)
          lastSessionEndTime = sessionEndTime;
          consecutiveSessions = 1;
          debugPrint(
            'Consecutive sessions: Starting with session at ${session.startAt}, count = $consecutiveSessions',
          );
        } else {
          // Calculate time between end of previous session and start of current session
          // Since we're going backwards in time, lastSessionEndTime is newer
          final timeDifference = lastSessionEndTime.difference(session.startAt);
          final minutesBetween = timeDifference.inMinutes;

          // If sessions are within 2 hours of each other (and not overlapping), consider them consecutive
          // timeDifference will be positive when lastSessionEndTime is after session.startAt
          // Use inMinutes for more precise comparison (2 hours = 120 minutes)
          if (minutesBetween >= 0 && minutesBetween <= 120) {
            consecutiveSessions++;
            lastSessionEndTime = sessionEndTime;
            debugPrint(
              'Consecutive sessions: Session at ${session.startAt} is consecutive ($minutesBetween min gap), count = $consecutiveSessions',
            );
          } else {
            debugPrint(
              'Consecutive sessions: Break detected at session ${session.startAt} ($minutesBetween min gap), stopping at count = $consecutiveSessions',
            );
            break;
          }
        }
      }

      debugPrint(
        'Consecutive sessions: Final count = $consecutiveSessions (from ${sessions.length} total sessions)',
      );
      return consecutiveSessions;
    } catch (e) {
      debugPrint('Error calculating consecutive sessions: $e');
      return 0;
    }
  }

  // Calculate daily sessions for today
  static Future<int> calculateDailySessions(String uid) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final sessions = await _getUserSessions(uid);

      return sessions.where((session) {
        return session.startAt.isAfter(startOfDay) &&
            session.startAt.isBefore(endOfDay);
      }).length;
    } catch (e) {
      debugPrint('Error calculating daily sessions: $e');
      return 0;
    }
  }

  // Calculate daily hours for today
  static Future<double> calculateDailyHours(String uid) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final sessions = await _getUserSessions(uid);

      final todaySessions = sessions.where((session) {
        return session.startAt.isAfter(startOfDay) &&
            session.startAt.isBefore(endOfDay);
      });

      double totalHours = 0;
      for (final session in todaySessions) {
        totalHours += session.duration.inMinutes / 60.0;
      }

      return totalHours;
    } catch (e) {
      debugPrint('Error calculating daily hours: $e');
      return 0.0;
    }
  }

  // Calculate weekly sessions for current week
  static Future<int> calculateWeeklySessions(String uid) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDay = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );
      final endOfWeek = startOfWeekDay.add(const Duration(days: 7));

      final sessions = await _getUserSessions(uid);

      return sessions.where((session) {
        return session.startAt.isAfter(startOfWeekDay) &&
            session.startAt.isBefore(endOfWeek);
      }).length;
    } catch (e) {
      debugPrint('Error calculating weekly sessions: $e');
      return 0;
    }
  }

  // Calculate consecutive days with at least X sessions per day
  // Returns the number of consecutive days meeting the requirement
  static Future<int> calculateConsecutiveDaysWithMinSessions(
    String uid,
    int minSessionsPerDay,
  ) async {
    try {
      final sessions = await _getUserSessions(uid);
      if (sessions.isEmpty) return 0;

      // Group sessions by date
      final sessionsByDate = <String, int>{};
      for (final session in sessions) {
        final dateKey = _getDateKey(session.startAt);
        sessionsByDate[dateKey] = (sessionsByDate[dateKey] ?? 0) + 1;
      }

      // Get all dates sorted (newest first)
      final dates = sessionsByDate.keys.toList()
        ..sort((a, b) => b.compareTo(a));

      if (dates.isEmpty) return 0;

      int consecutiveDays = 0;
      DateTime? lastDate;

      for (final dateKey in dates) {
        final dateParts = dateKey.split('-');
        final date = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );

        final sessionCount = sessionsByDate[dateKey] ?? 0;

        // Check if this day meets the minimum requirement
        if (sessionCount < minSessionsPerDay) {
          break; // Streak broken
        }

        if (lastDate == null) {
          // First valid day
          lastDate = date;
          consecutiveDays = 1;
        } else {
          final daysDifference = lastDate.difference(date).inDays;
          if (daysDifference == 1) {
            // Consecutive day
            consecutiveDays++;
            lastDate = date;
          } else if (daysDifference == 0) {
            // Same day, continue
            continue;
          } else {
            // Gap in days, streak broken
            break;
          }
        }
      }

      return consecutiveDays;
    } catch (e) {
      debugPrint('Error calculating consecutive days with min sessions: $e');
      return 0;
    }
  }

  // Get date key (YYYY-MM-DD)
  static String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Check if current session is early (before 9 AM)
  static bool isEarlySession() {
    return DateTime.now().hour < 9;
  }

  // Check if current session is late (after 10 PM)
  static bool isLateSession() {
    return DateTime.now().hour > 22;
  }

  // Check if current session is on weekend
  static bool isWeekendSession() {
    return DateTime.now().weekday >= 6;
  }

  // Get user sessions from Firestore
  static Future<List<SessionModel>> _getUserSessions(String uid) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .orderBy('startAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SessionModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting user sessions: $e');
      return [];
    }
  }
}
