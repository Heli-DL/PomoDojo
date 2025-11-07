import 'package:flutter/material.dart';

@immutable
class AchievementModel {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int requiredValue;
  final AchievementType type;
  final DateTime? unlockedAt;

  const AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.requiredValue,
    required this.type,
    this.unlockedAt,
  });

  factory AchievementModel.fromMap(Map<String, dynamic> map) {
    return AchievementModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      icon: IconData(map['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
      color: Color(map['color'] as int),
      requiredValue: map['requiredValue'] as int,
      type: AchievementType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AchievementType.sessions,
      ),
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.parse(map['unlockedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'color': color.toARGB32(),
      'requiredValue': requiredValue,
      'type': type.name,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  AchievementModel copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    Color? color,
    int? requiredValue,
    AchievementType? type,
    DateTime? unlockedAt,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      requiredValue: requiredValue ?? this.requiredValue,
      type: type ?? this.type,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  bool get isUnlocked => unlockedAt != null;

  @override
  String toString() {
    return 'AchievementModel(id: $id, name: $name, unlocked: $isUnlocked)';
  }
}

enum AchievementType {
  sessions,
  streak,
  totalPomodoros,
  dailySessions,
  dailyHours,
  earlySession,
  lateSession,
  consecutiveDays,
  consecutiveSessions,
  completedTasks,
  weekendSessions,
  weeklySessions,
  breakCompliance,
  phoneFocus,
  dndCompliance,
  taskPlanning,
  customDuration,
  statsViewing,
  dailyGoal,
  level,
}

// Predefined achievements
class Achievements {
  static const List<AchievementModel> all = [
    // Onboarding achievement
    AchievementModel(
      id: 'getting_started',
      name: 'Getting Started',
      description: 'Complete onboarding and set your first weekly goal',
      icon: Icons.rocket_launch,
      color: Color(0xFFFFC107), // Amber/Gold color
      requiredValue: 1,
      type: AchievementType.sessions, // Using sessions type as placeholder
    ),
    // Original achievements
    AchievementModel(
      id: 'first_focus',
      name: 'First Focus',
      description: 'Complete your first Pomodoro session',
      icon: Icons.emoji_events,
      color: Color(0xFFFF8A50), // Darker Peach for better visibility
      requiredValue: 1,
      type: AchievementType.sessions,
    ),
    AchievementModel(
      id: 'seven_day_streak',
      name: '7-Day Streak',
      description: 'Maintain a 7-day streak of daily sessions',
      icon: Icons.local_fire_department,
      color: Color(0xFFFF8A00), // Vibrant Orange for better visibility
      requiredValue: 7,
      type: AchievementType.streak,
    ),
    AchievementModel(
      id: 'hundred_pomodoros',
      name: '100 Total Pomodoros',
      description: 'Complete 100 Pomodoro sessions',
      icon: Icons.star,
      color: Color(0xFF9575CD), // Deeper Lavender for better visibility
      requiredValue: 100,
      type: AchievementType.totalPomodoros,
    ),

    // 🕒 Focus Milestones
    AchievementModel(
      id: 'deep_diver',
      name: 'Deep Diver',
      description: 'Complete 10 Pomodoros in a single day',
      icon: Icons.water_drop,
      color: Color(0xFF42A5F5), // Deeper Blue for better visibility
      requiredValue: 10,
      type: AchievementType.dailySessions,
    ),
    AchievementModel(
      id: 'marathon_mind',
      name: 'Marathon Mind',
      description: 'Focus for 8 hours total in one day',
      icon: Icons.directions_run,
      color: Color(0xFFFF6F00), // Deep Orange for better visibility
      requiredValue: 8,
      type: AchievementType.dailyHours,
    ),
    AchievementModel(
      id: 'early_riser',
      name: 'Early Riser',
      description: 'Complete your first Pomodoro before 8 AM',
      icon: Icons.wb_sunny,
      color: Color(0xFFFBC02D), // Deeper Yellow for better visibility
      requiredValue: 1,
      type: AchievementType.earlySession,
    ),
    AchievementModel(
      id: 'night_owl',
      name: 'Night Owl',
      description: 'Complete a Pomodoro after 11 PM',
      icon: Icons.nightlight_round,
      color: Color(0xFF7986CB), // Deeper Indigo for better visibility
      requiredValue: 1,
      type: AchievementType.lateSession,
    ),
    AchievementModel(
      id: 'consistency_king',
      name: 'Consistency King/Queen',
      description: 'Do at least 1 Pomodoro for 14 consecutive days',
      icon: Icons.king_bed,
      color: Color(0xFFBA68C8), // Deeper Mauve for better visibility
      requiredValue: 14,
      type: AchievementType.consecutiveDays,
    ),
    AchievementModel(
      id: 'focus_warrior',
      name: 'Focus Warrior',
      description: 'Reach 500 total Pomodoros',
      icon: Icons.sports_martial_arts,
      color: Color(0xFFE57373), // Deeper Rose for better visibility
      requiredValue: 500,
      type: AchievementType.totalPomodoros,
    ),
    AchievementModel(
      id: 'zen_master',
      name: 'Zen Master',
      description: 'Reach 1,000 total Pomodoros',
      icon: Icons.self_improvement,
      color: Color(0xFF26A69A), // Deeper Teal for better visibility
      requiredValue: 1000,
      type: AchievementType.totalPomodoros,
    ),
    AchievementModel(
      id: 'lightning_learner',
      name: 'Lightning Learner',
      description: 'Finish 4 Pomodoros without any pause',
      icon: Icons.flash_on,
      color: Color(0xFFFFC107), // Deeper Amber for better visibility
      requiredValue: 4,
      type: AchievementType.consecutiveSessions,
    ),
    AchievementModel(
      id: 'focus_flow',
      name: 'Focus Flow',
      description:
          'Complete 3 consecutive Pomodoro sessions without interruption',
      icon: Icons.trending_up,
      color: Color(0xFF42A5F5), // Deeper Blue for better visibility
      requiredValue: 3,
      type: AchievementType.consecutiveSessions,
    ),
    AchievementModel(
      id: 'task_terminator',
      name: 'Task Terminator',
      description: 'Complete 50 different tasks using Pomodoros',
      icon: Icons.task_alt,
      color: Color(0xFF00BCD4), // Deeper Cyan for better visibility
      requiredValue: 50,
      type: AchievementType.completedTasks,
    ),

    // 🔥 Streak & Discipline Achievements
    AchievementModel(
      id: 'weekend_warrior',
      name: 'Weekend Warrior',
      description: 'Complete 5 Pomodoros on a single weekend day',
      icon: Icons.weekend,
      color: Color(0xFFEC407A), // Deeper Pink for better visibility
      requiredValue: 5,
      type: AchievementType.dailySessions,
    ),
    AchievementModel(
      id: 'twenty_one_day_habit',
      name: '21-Day Habit',
      description: 'Maintain a 21-day streak',
      icon: Icons.calendar_today,
      color: Color(0xFFFF8A50), // Darker Peach for better visibility
      requiredValue: 21,
      type: AchievementType.streak,
    ),
    AchievementModel(
      id: 'one_month_milestone',
      name: 'One-Month Milestone',
      description: 'Maintain a 30-day streak',
      icon: Icons.calendar_month,
      color: Color(0xFF42A5F5), // Deeper Blue for better visibility
      requiredValue: 30,
      type: AchievementType.streak,
    ),
    AchievementModel(
      id: 'unstoppable',
      name: 'Unstoppable',
      description: '60-day streak',
      icon: Icons.rocket_launch,
      color: Color(0xFF9575CD), // Deeper Lavender for better visibility
      requiredValue: 60,
      type: AchievementType.streak,
    ),
    AchievementModel(
      id: 'year_of_focus',
      name: 'Year of Focus',
      description: '365-day streak',
      icon: Icons.celebration,
      color: Color(0xFFFF8A50), // Darker Peach for better visibility
      requiredValue: 365,
      type: AchievementType.streak,
    ),
    AchievementModel(
      id: 'streak_starter',
      name: 'Streak Starter',
      description: 'Complete your first 3-day streak',
      icon: Icons.trending_up,
      color: Color(0xFFFF8A00), // Vibrant Orange for better visibility
      requiredValue: 3,
      type: AchievementType.streak,
    ),
    AchievementModel(
      id: 'daily_discipline',
      name: 'Daily Discipline',
      description: 'Do at least 3 Pomodoros every day for a week',
      icon: Icons.schedule,
      color: Color(0xFF66BB6A), // Deeper Sage/Green for better visibility
      requiredValue: 7,
      type: AchievementType.weeklySessions,
    ),
    AchievementModel(
      id: 'balanced_life',
      name: 'Balanced Life',
      description:
          'Take all scheduled breaks for one full week without skipping',
      icon: Icons.balance,
      color: Color(0xFF8BC34A), // Deeper Green for better visibility
      requiredValue: 7,
      type: AchievementType.breakCompliance,
    ),

    // 🧠 Growth & Productivity
    AchievementModel(
      id: 'task_crusher',
      name: 'Task Crusher',
      description: 'Mark 100 tasks as completed',
      icon: Icons.check_circle,
      color: Color(0xFF66BB6A), // Deeper Sage/Green for better visibility
      requiredValue: 100,
      type: AchievementType.completedTasks,
    ),
    AchievementModel(
      id: 'project_master',
      name: 'Project Master',
      description: 'Complete 10 high-priority tasks',
      icon: Icons.work,
      color: Color(0xFF42A5F5), // Deeper Blue for better visibility
      requiredValue: 10,
      type: AchievementType.completedTasks,
    ),
    AchievementModel(
      id: 'flow_state',
      name: 'Flow State',
      description: 'Stay focused for 2+ hours without touching your phone',
      icon: Icons.phone_android,
      color: Color(0xFF9575CD), // Deeper Lavender for better visibility
      requiredValue: 2,
      type: AchievementType.phoneFocus,
    ),
    AchievementModel(
      id: 'mindful_worker',
      name: 'Mindful Worker',
      description: 'Enable Do Not Disturb mode every session for a full week',
      icon: Icons.do_not_disturb,
      color: Color(0xFF7986CB), // Deeper Indigo for better visibility
      requiredValue: 7,
      type: AchievementType.dndCompliance,
    ),
    AchievementModel(
      id: 'planner_pro',
      name: 'Planner Pro',
      description: 'Add 20 tasks before starting your day',
      icon: Icons.assignment,
      color: Color(0xFF26A69A), // Deeper Teal for better visibility
      requiredValue: 20,
      type: AchievementType.taskPlanning,
    ),
    AchievementModel(
      id: 'time_alchemist',
      name: 'Time Alchemist',
      description: 'Customize your own Pomodoro durations for the first time',
      icon: Icons.timer,
      color: Color(0xFFFF8A50), // Darker Peach for better visibility
      requiredValue: 1,
      type: AchievementType.customDuration,
    ),
    AchievementModel(
      id: 'data_driven',
      name: 'Data-Driven',
      description: 'View your weekly stats 5 times',
      icon: Icons.analytics,
      color: Color(0xFF607D8B), // Deeper Blue Gray for better visibility
      requiredValue: 5,
      type: AchievementType.statsViewing,
    ),

    // 🎯 Weekly Goal Achievements
    AchievementModel(
      id: 'weekly_starter',
      name: 'Weekly Starter',
      description: 'Complete your weekly goal for the first time',
      icon: Icons.play_circle,
      color: Color(0xFF66BB6A), // Deeper Sage/Green for better visibility
      requiredValue: 1,
      type: AchievementType.dailyGoal,
    ),
    AchievementModel(
      id: 'two_week_streak',
      name: 'Two-Week Streak',
      description: 'Complete your weekly goal two weeks in a row',
      icon: Icons.trending_up,
      color: Color(0xFF8BC34A), // Deeper Green for better visibility
      requiredValue: 2,
      type: AchievementType.dailyGoal,
    ),
    AchievementModel(
      id: 'three_week_streak',
      name: 'Three-Week Streak',
      description: 'Complete your weekly goal three weeks in a row',
      icon: Icons.trending_up,
      color: Color(0xFF66BB6A), // Deeper Sage/Green for better visibility
      requiredValue: 3,
      type: AchievementType.dailyGoal,
    ),
    AchievementModel(
      id: 'monthly_warrior',
      name: 'Monthly Warrior',
      description: 'Complete your weekly goal four weeks in a row',
      icon: Icons.calendar_today,
      color: Color(0xFF26A69A), // Deeper Teal for better visibility
      requiredValue: 4,
      type: AchievementType.dailyGoal,
    ),
    AchievementModel(
      id: 'quarterly_champion',
      name: 'Quarterly Champion',
      description: 'Complete your weekly goal twelve weeks in a row',
      icon: Icons.calendar_view_week,
      color: Color(0xFF42A5F5), // Deeper Blue for better visibility
      requiredValue: 12,
      type: AchievementType.dailyGoal,
    ),
    AchievementModel(
      id: 'half_year_hero',
      name: 'Half-Year Hero',
      description: 'Complete your weekly goal twenty-six weeks in a row',
      icon: Icons.calendar_month,
      color: Color(0xFF7986CB), // Deeper Indigo for better visibility
      requiredValue: 26,
      type: AchievementType.dailyGoal,
    ),
    AchievementModel(
      id: 'yearly_master',
      name: 'Yearly Master',
      description: 'Complete your weekly goal fifty-two weeks in a row',
      icon: Icons.calendar_month,
      color: Color(0xFF9575CD), // Deeper Lavender for better visibility
      requiredValue: 52,
      type: AchievementType.dailyGoal,
    ),
    AchievementModel(
      id: 'overachiever_weekly',
      name: 'Overachiever (Weekly)',
      description: 'Exceed your weekly goal by 50% or more',
      icon: Icons.rocket_launch,
      color: Color(0xFFFF8A00), // Vibrant Orange for better visibility
      requiredValue: 1,
      type: AchievementType.dailyGoal,
    ),
    AchievementModel(
      id: 'double_down_weekly',
      name: 'Double Down (Weekly)',
      description: 'Complete double your weekly goal in one week',
      icon: Icons.double_arrow,
      color: Color(0xFFFF6F00), // Deep Orange for better visibility
      requiredValue: 1,
      type: AchievementType.dailyGoal,
    ),
    AchievementModel(
      id: 'triple_threat_weekly',
      name: 'Triple Threat (Weekly)',
      description: 'Complete triple your weekly goal in one week',
      icon: Icons.trending_up,
      color: Color(0xFFE57373), // Deeper Rose for better visibility
      requiredValue: 1,
      type: AchievementType.dailyGoal,
    ),
    AchievementModel(
      id: 'consistency_king_weekly',
      name: 'Consistency King (Weekly)',
      description: 'Complete your weekly goal 8 weeks in a row',
      icon: Icons.king_bed,
      color: Color(0xFFFF8A50), // Darker Peach for better visibility
      requiredValue: 8,
      type: AchievementType.dailyGoal,
    ),
    AchievementModel(
      id: 'streak_master_weekly',
      name: 'Streak Master (Weekly)',
      description: 'Complete your weekly goal 20 weeks in a row',
      icon: Icons.local_fire_department,
      color: Color(0xFFBA68C8), // Deeper Mauve for better visibility
      requiredValue: 20,
      type: AchievementType.dailyGoal,
    ),
    AchievementModel(
      id: 'unstoppable_weekly',
      name: 'Unstoppable (Weekly)',
      description: 'Complete your weekly goal 40 weeks in a row',
      icon: Icons.rocket,
      color: Color(0xFFEC407A), // Deeper Pink for better visibility
      requiredValue: 40,
      type: AchievementType.dailyGoal,
    ),
    AchievementModel(
      id: 'legendary_weekly',
      name: 'Legendary (Weekly)',
      description: 'Complete your weekly goal 80 weeks in a row',
      icon: Icons.star,
      color: Color(0xFFFF8A50), // Darker Peach for better visibility
      requiredValue: 80,
      type: AchievementType.dailyGoal,
    ),
    AchievementModel(
      id: 'mythical_weekly',
      name: 'Mythical (Weekly)',
      description: 'Complete your weekly goal 100 weeks in a row',
      icon: Icons.celebration,
      color: Color(0xFFFF8A50), // Darker Peach for better visibility
      requiredValue: 100,
      type: AchievementType.dailyGoal,
    ),
    AchievementModel(
      id: 'comeback_champion_weekly',
      name: 'Comeback Champion (Weekly)',
      description: 'Complete your weekly goal after breaking a long streak',
      icon: Icons.refresh,
      color: Color(0xFF00BCD4), // Deeper Cyan for better visibility
      requiredValue: 1,
      type: AchievementType.dailyGoal,
    ),

    // 🏆 Special Achievements
    AchievementModel(
      id: 'grandmaster',
      name: 'Grandmaster',
      description: 'Reach the highest rank of Grandmaster',
      icon: Icons.emoji_events,
      color: Color(0xFF9575CD), // Deeper Lavender for better visibility
      requiredValue: 11, // Level 11+ is Grandmaster rank
      type: AchievementType.level,
    ),
    AchievementModel(
      id: 'focus_legend',
      name: 'Focus Legend',
      description: 'Complete 2,000 total Pomodoros',
      icon: Icons.star,
      color: Color(0xFFFF8A50), // Darker Peach for better visibility
      requiredValue: 2000,
      type: AchievementType.totalPomodoros,
    ),
    AchievementModel(
      id: 'time_master',
      name: 'Time Master',
      description: 'Focus for 500 hours total',
      icon: Icons.schedule,
      color: Color(0xFF42A5F5), // Deeper Blue for better visibility
      requiredValue: 500,
      type: AchievementType.totalPomodoros,
    ),
    AchievementModel(
      id: 'consistency_legend',
      name: 'Consistency Legend',
      description: 'Maintain a 100-day streak',
      icon: Icons.local_fire_department,
      color: Color(0xFFE57373), // Deeper Rose for better visibility
      requiredValue: 100,
      type: AchievementType.streak,
    ),
    AchievementModel(
      id: 'productivity_god',
      name: 'Productivity God',
      description: 'Complete 5,000 total Pomodoros',
      icon: Icons.auto_awesome,
      color: Color(0xFFBA68C8), // Deeper Mauve for better visibility
      requiredValue: 5000,
      type: AchievementType.totalPomodoros,
    ),
    AchievementModel(
      id: 'eternal_focus',
      name: 'Eternal Focus',
      description: 'Focus for 1,000 hours total',
      icon: Icons.all_inclusive,
      color: Color(0xFF26A69A), // Deeper Teal for better visibility
      requiredValue: 1000,
      type: AchievementType.totalPomodoros,
    ),
  ];

  static AchievementModel? getById(String id) {
    try {
      return all.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }
}
