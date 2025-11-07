import 'package:flutter/material.dart';

class OnboardingData {
  final List<String> selectedGoals;
  final PomodoroPreset selectedPreset;
  final int weeklyGoal;
  final bool notificationsEnabled;
  final bool doNotDisturbEnabled;

  const OnboardingData({
    this.selectedGoals = const [],
    required this.selectedPreset,
    this.weeklyGoal = 20,
    this.notificationsEnabled = false,
    this.doNotDisturbEnabled = false,
  });

  OnboardingData copyWith({
    List<String>? selectedGoals,
    PomodoroPreset? selectedPreset,
    int? weeklyGoal,
    bool? notificationsEnabled,
    bool? doNotDisturbEnabled,
  }) {
    return OnboardingData(
      selectedGoals: selectedGoals ?? this.selectedGoals,
      selectedPreset: selectedPreset ?? this.selectedPreset,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      doNotDisturbEnabled: doNotDisturbEnabled ?? this.doNotDisturbEnabled,
    );
  }
}

class PomodoroPreset {
  final String name;
  final int focusMinutes;
  final int breakMinutes;
  final String description;

  const PomodoroPreset({
    required this.name,
    required this.focusMinutes,
    required this.breakMinutes,
    required this.description,
  });

  static const List<PomodoroPreset> all = [
    PomodoroPreset(
      name: '25/5',
      focusMinutes: 25,
      breakMinutes: 5,
      description: 'Classic Pomodoro',
    ),
    PomodoroPreset(
      name: '50/10',
      focusMinutes: 50,
      breakMinutes: 10,
      description: 'Deep work',
    ),
    PomodoroPreset(
      name: '90/20',
      focusMinutes: 90,
      breakMinutes: 20,
      description: 'Flow state',
    ),
    PomodoroPreset(
      name: '15/3',
      focusMinutes: 15,
      breakMinutes: 3,
      description: 'Micro sessions',
    ),
  ];
}

class OnboardingGoal {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  static const List<OnboardingGoal> all = [
    OnboardingGoal(
      id: 'study_effectively',
      title: 'Study more effectively',
      description: 'Improve focus and retention',
      icon: Icons.school,
      color: Colors.blue,
    ),
    OnboardingGoal(
      id: 'work_focus',
      title: 'Improve focus at work',
      description: 'Stay productive and organized',
      icon: Icons.work,
      color: Colors.green,
    ),
    OnboardingGoal(
      id: 'time_management',
      title: 'Manage time better',
      description: 'Structure your day efficiently',
      icon: Icons.schedule,
      color: Colors.orange,
    ),
    OnboardingGoal(
      id: 'daily_consistency',
      title: 'Stay consistent daily',
      description: 'Build lasting habits',
      icon: Icons.trending_up,
      color: Colors.purple,
    ),
    OnboardingGoal(
      id: 'reduce_burnout',
      title: 'Reduce burnout',
      description: 'Balance work and rest',
      icon: Icons.spa,
      color: Colors.teal,
    ),
  ];
}

class OnboardingStep {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  static const List<OnboardingStep> howItWorks = [
    OnboardingStep(
      id: 'focus',
      title: 'Focus',
      description:
          'Work in short, structured sessions to stay sharp and productive.',
      icon: Icons.psychology,
      color: Colors.blue,
    ),
    OnboardingStep(
      id: 'rest',
      title: 'Rest',
      description: 'Recharge with mindful breaks — relax, stretch, or breathe.',
      icon: Icons.coffee,
      color: Colors.green,
    ),
    OnboardingStep(
      id: 'grow',
      title: 'Grow',
      description:
          'Earn achievements, track streaks, and see your progress over time.',
      icon: Icons.trending_up,
      color: Colors.purple,
    ),
  ];
}

