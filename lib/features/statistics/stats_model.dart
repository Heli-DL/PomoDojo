import 'package:flutter/material.dart';

class TopicSlice {
  final String title;
  final Color color;
  final int minutes;
  const TopicSlice({
    required this.title,
    required this.color,
    required this.minutes,
  });
}

class DayBucket {
  // Minutes per topic for a single day
  final DateTime day; // local midnight
  final Map<String, int> minutesByTopic; // topicTitle -> minutes
  final Map<String, Color> colorsByTopic;
  final String label; // day label (e.g., "Mon", "Tue")

  DayBucket({
    required this.day,
    required this.minutesByTopic,
    required this.colorsByTopic,
    required this.label,
  });

  int get totalMinutes => minutesByTopic.values.fold(0, (a, b) => a + b);
}

class WeeklyStats {
  final int totalMinutes;
  final double dailyAverageMinutes;
  final int streakDays;
  final List<TopicSlice> topTopics; // sorted desc by minutes
  final List<DayBucket> week; // 7 days Mon..Sun (or locale)
  final int sessionsCount;
  final String? topTopicTitle;
  final int? topTopicMinutes;
  const WeeklyStats({
    required this.totalMinutes,
    required this.dailyAverageMinutes,
    required this.streakDays,
    required this.topTopics,
    required this.week,
    required this.sessionsCount,
    required this.topTopicTitle,
    required this.topTopicMinutes,
  });
}
