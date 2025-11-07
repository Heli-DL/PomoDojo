import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'stats_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'stats_repository.dart';
import '../topics/topic_model.dart';
import '../topics/topic_controller.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

enum StatsRange { week, month, allTime }

class StatsRangeNotifier extends Notifier<StatsRange> {
  @override
  StatsRange build() => StatsRange.week;

  void setRange(StatsRange range) {
    state = range;
  }
}

final statsRangeProvider = NotifierProvider<StatsRangeNotifier, StatsRange>(() {
  return StatsRangeNotifier();
});

/// Computes start/end for current range in LOCAL time.
({DateTime from, DateTime to}) _rangeBounds(StatsRange r) {
  final now = DateTime.now();
  if (r == StatsRange.week) {
    final weekday = now.weekday; // 1=Mon..7=Sun
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: weekday - 1));
    final end = start.add(const Duration(days: 7));
    return (from: start, to: end);
  } else if (r == StatsRange.month) {
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return (from: start, to: end);
  } else {
    // All time - start from a very early date (e.g., 2020-01-01)
    final start = DateTime(2020, 1, 1);
    final end = DateTime(now.year, now.month, now.day + 1);
    return (from: start, to: end);
  }
}

/// Generates day label for the given date
String _getDayLabel(DateTime date, StatsRange range) {
  if (range == StatsRange.week) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  } else if (range == StatsRange.month) {
    return '${date.day}';
  } else {
    // All time - show month abbreviation
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

final weeklyStatsProvider = StreamProvider<WeeklyStats>((ref) {
  final range = ref.watch(statsRangeProvider);
  final bounds = _rangeBounds(range);
  final repo = ref.watch(statsRepositoryProvider);
  final topicsAsync = ref.watch(topicsControllerProvider);

  debugPrint(
    'Stats: Range bounds - From: ${bounds.from}, To: ${bounds.to}, Range: $range',
  );

  // Fetch wider window for streak while we still display only current range
  final streakFrom = DateTime.now().subtract(const Duration(days: 30));
  return repo.watchSessionModels(from: streakFrom, to: bounds.to).map((
    sessions,
  ) {
    try {
      debugPrint(
        'Stats: Processing ${sessions.length} sessions for range $streakFrom to ${bounds.to}',
      );

      // Build day buckets for the selected range
      final days = <DayBucket>[];
      int totalDays;
      if (range == StatsRange.week) {
        totalDays = 7;
      } else if (range == StatsRange.month) {
        totalDays = DateTime(
          bounds.to.year,
          bounds.to.month,
          0,
        ).day; // days in month
      } else {
        // All time - group by month
        // Calculate number of months from start to end (inclusive of current month)
        final now = DateTime.now();
        final endMonth = DateTime(now.year, now.month, 1); // Current month
        final startMonth = DateTime(bounds.from.year, bounds.from.month, 1);
        final monthsDiff =
            (endMonth.year - startMonth.year) * 12 +
            (endMonth.month - startMonth.month) +
            1; // +1 to include current month
        totalDays = monthsDiff.clamp(1, 120); // Cap at 10 years (120 months)
      }

      // Pre-seed buckets
      if (range == StatsRange.allTime) {
        // For all time, create monthly buckets
        final now = DateTime.now();
        final startMonth = DateTime(bounds.from.year, bounds.from.month, 1);
        final endMonth = DateTime(
          now.year,
          now.month,
          1,
        ); // Current month (inclusive)
        int monthCount = 0;
        var month = startMonth;
        // Include the current month by using <= instead of <
        while ((month.isBefore(endMonth) || month.isAtSameMomentAs(endMonth)) &&
            monthCount < totalDays) {
          final dayBucket = DayBucket(
            day: month,
            minutesByTopic: {},
            colorsByTopic: {},
            label: _getDayLabel(month, range),
          );
          days.add(dayBucket);
          debugPrint(
            'Stats: Created month bucket $monthCount: ${dayBucket.day} (${dayBucket.label})',
          );
          // Move to next month
          month = DateTime(month.year, month.month + 1, 1);
          monthCount++;
        }
      } else {
        // For week/month, create daily buckets
        for (int i = 0; i < totalDays; i++) {
          final day = bounds.from.add(Duration(days: i));
          final dayBucket = DayBucket(
            day: DateTime(day.year, day.month, day.day),
            minutesByTopic: {},
            colorsByTopic: {},
            label: _getDayLabel(day, range),
          );
          days.add(dayBucket);
          debugPrint('Stats: Created day bucket $i: ${dayBucket.day}');
        }
      }

      int totalMinutes = 0;
      int sessionsCount = 0;
      final topicTotals = HashMap<String, int>();
      final topicColors = HashMap<String, Color>();

      // Get user topics for color matching
      final userTopics = topicsAsync.when(
        data: (topics) => topics,
        loading: () => <Topic>[],
        error: (_, _) => <Topic>[],
      );

      for (final session in sessions) {
        final endedAt = session.endAt.toLocal();
        final inDisplayRange =
            !endedAt.isBefore(bounds.from) && endedAt.isBefore(bounds.to);
        if (inDisplayRange) {
          sessionsCount++;
        }
        final minutes = session.duration.inMinutes;
        if (inDisplayRange) {
          totalMinutes += minutes;
        }
        final topic = (session.topicName?.trim().isNotEmpty == true)
            ? session.topicName!
            : 'Other';
        final color = _getTopicColor(topic, userTopics);

        debugPrint(
          'Stats: Processing session - Topic: $topic, Minutes: $minutes, EndAt: $endedAt, SessionType: ${session.sessionType}',
        );

        // Only count focus sessions inside display window for topics/statistics
        if (inDisplayRange && session.sessionType == 'focus') {
          topicTotals.update(
            topic,
            (v) => v + minutes,
            ifAbsent: () => minutes,
          );
          topicColors.putIfAbsent(topic, () => color);
        }

        // Put into the correct day/month bucket ONLY if within display range
        if (endedAt.isBefore(bounds.from) || !endedAt.isBefore(bounds.to)) {
          // Skip sessions outside display bounds for charting
          continue;
        }

        int idx;
        if (range == StatsRange.allTime) {
          // For all time, find the month bucket
          final sessionMonth = DateTime(endedAt.year, endedAt.month, 1);
          idx = days.indexWhere(
            (db) =>
                db.day.year == sessionMonth.year &&
                db.day.month == sessionMonth.month,
          );
        } else {
          // For week/month, calculate day index
          final boundsStart = DateTime(
            bounds.from.year,
            bounds.from.month,
            bounds.from.day,
          );
          idx = endedAt.difference(boundsStart).inDays;
        }

        debugPrint(
          'Stats: Session calculation - EndAt: $endedAt, Index: $idx, DaysLength: ${days.length}',
        );

        if (idx >= 0 && idx < days.length) {
          final db = days[idx];

          // Only add focus sessions to day buckets for streak calculation
          if (session.sessionType == 'focus') {
            db.minutesByTopic.update(
              topic,
              (v) => v + minutes,
              ifAbsent: () => minutes,
            );
            db.colorsByTopic.putIfAbsent(topic, () => color);
            debugPrint(
              'Stats: Focus session assigned to day ${db.day} with $minutes minutes',
            );
          } else {
            debugPrint(
              'Stats: Break session (${session.sessionType}) not counted for streak',
            );
          }
        } else {
          debugPrint(
            'Stats: Session not assigned - Index $idx is out of bounds (0-${days.length - 1})',
          );
        }
      }

      final slices =
          topicTotals.entries
              .map(
                (e) => TopicSlice(
                  title: e.key,
                  color:
                      topicColors[e.key] ?? _getTopicColor(e.key, userTopics),
                  minutes: e.value,
                ),
              )
              .toList()
            ..sort((a, b) => b.minutes.compareTo(a.minutes));

      // Calculate average based on range type
      double dailyAvg;
      if (range == StatsRange.allTime) {
        // For all time, calculate monthly average
        dailyAvg = days.isEmpty ? 0.0 : totalMinutes / days.length;
      } else {
        // For week/month, calculate daily average
        dailyAvg = days.isEmpty ? 0.0 : totalMinutes / days.length;
      }

      // Streak (current consecutive days with >= 1 focus session) from sessions only
      // Counts backwards from today, so if you have sessions yesterday but not today,
      // the streak is still 1 until tomorrow
      final focusDays = <DateTime>{};
      for (final s in sessions) {
        if (s.sessionType == 'focus') {
          final d = s.endAt.toLocal();
          final sessionDate = DateTime(d.year, d.month, d.day);
          focusDays.add(sessionDate);
        }
      }

      int streak = 0;
      bool startedCounting = false;
      final todayLocal = DateTime.now();
      final todayDateOnly = DateTime(
        todayLocal.year,
        todayLocal.month,
        todayLocal.day,
      );

      // Check up to 365 days back (reasonable limit)
      for (int i = 0; i < 365; i++) {
        final checkDate = todayDateOnly.subtract(Duration(days: i));

        // Check if this date has any sessions (explicit date comparison)
        final hasSession = focusDays.any((date) {
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

      final result = WeeklyStats(
        totalMinutes: totalMinutes,
        dailyAverageMinutes: dailyAvg,
        streakDays: streak,
        topTopics: slices,
        week: days,
        sessionsCount: sessionsCount,
        topTopicTitle: slices.isEmpty ? null : slices.first.title,
        topTopicMinutes: slices.isEmpty ? null : slices.first.minutes,
      );

      debugPrint(
        'Stats: Final result - Total minutes: $totalMinutes, Sessions: $sessionsCount, Streak: $streak',
      );
      return result;
    } catch (e, st) {
      debugPrint('Stats: ERROR building weekly stats: $e\n$st');
      // Always emit a safe value to avoid infinite loading in UI
      return WeeklyStats(
        totalMinutes: 0,
        dailyAverageMinutes: 0,
        streakDays: 0,
        topTopics: const [],
        week: range == StatsRange.allTime
            ? [
                // For all time, create empty monthly buckets
                DayBucket(
                  day: DateTime(bounds.from.year, bounds.from.month, 1),
                  minutesByTopic: {},
                  colorsByTopic: {},
                  label: _getDayLabel(
                    DateTime(bounds.from.year, bounds.from.month, 1),
                    range,
                  ),
                ),
              ]
            : [
                for (
                  int i = 0;
                  i <
                      (range == StatsRange.week
                          ? 7
                          : DateTime(bounds.to.year, bounds.to.month, 0).day);
                  i++
                )
                  DayBucket(
                    day: DateTime(
                      bounds.from.year,
                      bounds.from.month,
                      bounds.from.day,
                    ).add(Duration(days: i)),
                    minutesByTopic: {},
                    colorsByTopic: {},
                    label: _getDayLabel(
                      bounds.from.add(Duration(days: i)),
                      range,
                    ),
                  ),
              ],
        sessionsCount: 0,
        topTopicTitle: null,
        topTopicMinutes: null,
      );
    }
  });
});

Color _getTopicColor(String topic, [List<Topic>? userTopics]) {
  // First check user-defined topics
  if (userTopics != null) {
    final userTopic = userTopics.firstWhere(
      (t) => t.name.toLowerCase() == topic.toLowerCase(),
      orElse: () => const Topic(id: '', name: '', color: 0),
    );

    if (userTopic.id.isNotEmpty) {
      return Color(userTopic.color);
    }
  }

  // Then check predefined topics
  final predefinedTopic = predefinedTopics.firstWhere(
    (t) => t.name.toLowerCase() == topic.toLowerCase(),
    orElse: () => const Topic(id: '', name: '', color: 0),
  );

  if (predefinedTopic.id.isNotEmpty) {
    return Color(predefinedTopic.color);
  }

  // Fallback to muted/pastel colors based on topic name hash
  final colors = [
    const Color(0xFFB39DDB), // Muted Lavender
    const Color(0xFFA5D6A7), // Muted Sage
    const Color(0xFFFFCC80), // Muted Peach
    const Color(0xFFCE93D8), // Muted Mauve
    const Color(0xFFEF9A9A), // Muted Rose
    const Color(0xFF80CBC4), // Muted Teal
    const Color(0xFF9FA8DA), // Muted Indigo
    const Color(0xFFF48FB1), // Muted Pink
  ];

  final hash = topic.hashCode;
  return colors[hash.abs() % colors.length];
}
