import 'pomodoro_session.dart';
import '../progression/progression_celebration_service.dart';
import '../achievements/achievement_model.dart';

class TimerState {
  final Duration remaining;
  final Duration totalDuration;
  final bool isRunning;
  final bool isPaused;
  final DateTime? endAt;
  final PomodoroSession? pomodoroSession;
  final bool isPomodoroMode;
  final ProgressionCelebration? celebration;
  final List<AchievementModel>? achievementCelebrations;
  final bool? weeklyGoalCompleted;

  // Settings
  final bool focusShieldEnabled;
  final bool sessionNotificationsEnabled;
  final bool breakNotificationsEnabled;
  final bool autoStartEnabled;

  const TimerState({
    required this.remaining,
    required this.totalDuration,
    required this.isRunning,
    this.isPaused = false,
    this.endAt,
    this.pomodoroSession,
    this.isPomodoroMode = false,
    this.celebration,
    this.achievementCelebrations,
    this.weeklyGoalCompleted,
    this.focusShieldEnabled = false,
    this.sessionNotificationsEnabled = true,
    this.breakNotificationsEnabled = true,
    this.autoStartEnabled = false,
  });

  factory TimerState.initial() => const TimerState(
    remaining: Duration.zero,
    totalDuration: Duration.zero,
    isRunning: false,
    focusShieldEnabled: false,
    sessionNotificationsEnabled: true,
    breakNotificationsEnabled: true,
    autoStartEnabled: false,
  );
  TimerState copyWith({
    Duration? remaining,
    Duration? totalDuration,
    bool? isRunning,
    bool? isPaused,
    DateTime? endAt,
    PomodoroSession? pomodoroSession,
    bool? isPomodoroMode,
    ProgressionCelebration? celebration,
    List<AchievementModel>? achievementCelebrations,
    bool? weeklyGoalCompleted,
    bool? focusShieldEnabled,
    bool? sessionNotificationsEnabled,
    bool? breakNotificationsEnabled,
    bool? autoStartEnabled,
  }) {
    return TimerState(
      remaining: remaining ?? this.remaining,
      totalDuration: totalDuration ?? this.totalDuration,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      endAt: endAt ?? this.endAt,
      pomodoroSession: pomodoroSession ?? this.pomodoroSession,
      isPomodoroMode: isPomodoroMode ?? this.isPomodoroMode,
      celebration: celebration ?? this.celebration,
      achievementCelebrations:
          achievementCelebrations ?? this.achievementCelebrations,
      weeklyGoalCompleted: weeklyGoalCompleted ?? this.weeklyGoalCompleted,
      focusShieldEnabled: focusShieldEnabled ?? this.focusShieldEnabled,
      sessionNotificationsEnabled:
          sessionNotificationsEnabled ?? this.sessionNotificationsEnabled,
      breakNotificationsEnabled:
          breakNotificationsEnabled ?? this.breakNotificationsEnabled,
      autoStartEnabled: autoStartEnabled ?? this.autoStartEnabled,
    );
  }

  @override
  String toString() {
    return 'TimerState(remaining: $remaining, totalDuration: $totalDuration, isRunning: $isRunning, isPaused: $isPaused, endAt: $endAt, pomodoroSession: $pomodoroSession, isPomodoroMode: $isPomodoroMode, celebration: $celebration, achievementCelebrations: $achievementCelebrations, weeklyGoalCompleted: $weeklyGoalCompleted, focusShieldEnabled: $focusShieldEnabled, sessionNotificationsEnabled: $sessionNotificationsEnabled, breakNotificationsEnabled: $breakNotificationsEnabled, autoStartEnabled: $autoStartEnabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimerState &&
        other.remaining == remaining &&
        other.totalDuration == totalDuration &&
        other.isRunning == isRunning &&
        other.isPaused == isPaused &&
        other.endAt == endAt &&
        other.pomodoroSession == pomodoroSession &&
        other.isPomodoroMode == isPomodoroMode &&
        other.celebration == celebration &&
        other.achievementCelebrations == achievementCelebrations &&
        other.weeklyGoalCompleted == weeklyGoalCompleted &&
        other.focusShieldEnabled == focusShieldEnabled &&
        other.sessionNotificationsEnabled == sessionNotificationsEnabled &&
        other.breakNotificationsEnabled == breakNotificationsEnabled &&
        other.autoStartEnabled == autoStartEnabled;
  }

  @override
  int get hashCode => Object.hash(
    remaining,
    totalDuration,
    isRunning,
    isPaused,
    endAt,
    pomodoroSession,
    isPomodoroMode,
    celebration,
    achievementCelebrations,
    weeklyGoalCompleted,
    focusShieldEnabled,
    sessionNotificationsEnabled,
    breakNotificationsEnabled,
    autoStartEnabled,
  );
}
