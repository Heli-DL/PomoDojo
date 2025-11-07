import 'pomodoro_presets.dart';

enum PomodoroSessionType { focus, shortBreak, longBreak }

class PomodoroSession {
  final PomodoroPreset preset;
  final PomodoroSessionType currentSessionType;
  final int currentCycle;
  final int completedCycles;
  final Duration sessionDuration;
  final Duration remainingTime;
  final bool isRunning;
  final DateTime? sessionStartTime;
  final DateTime? sessionEndTime;
  final String? topicId;
  final String? topicName;

  const PomodoroSession({
    required this.preset,
    required this.currentSessionType,
    required this.currentCycle,
    required this.completedCycles,
    required this.sessionDuration,
    required this.remainingTime,
    required this.isRunning,
    this.sessionStartTime,
    this.sessionEndTime,
    this.topicId,
    this.topicName,
  });

  factory PomodoroSession.initial(
    PomodoroPreset preset, {
    String? topicId,
    String? topicName,
  }) {
    return PomodoroSession(
      preset: preset,
      currentSessionType: PomodoroSessionType.focus,
      currentCycle: 1,
      completedCycles: 0,
      sessionDuration: preset.focus,
      remainingTime: preset.focus,
      isRunning: false,
      topicId: topicId,
      topicName: topicName,
    );
  }

  //Star session
  PomodoroSession start() {
    return copyWith(isRunning: true, sessionStartTime: DateTime.now());
  }

  // Stop session
  PomodoroSession stop() {
    return copyWith(isRunning: false, sessionEndTime: DateTime.now());
  }

  // Complete current session and move to next
  PomodoroSession completeSession() {
    final isFocusSession = currentSessionType == PomodoroSessionType.focus;
    final isLastFocusCycle =
        isFocusSession && currentCycle >= preset.longBreakAfterCycles;

    PomodoroSessionType nextSessionType;
    int nextCycle;
    int nextCompletedCycles;
    Duration nextSessionDuration;

    if (isFocusSession) {
      if (isLastFocusCycle) {
        // Move to long break and reset cycle
        nextSessionType = PomodoroSessionType.longBreak;
        nextCycle = 1;
        nextCompletedCycles = completedCycles + 1;
        nextSessionDuration = preset.longBreak;
      } else {
        // Move to short break and increment cycle
        nextSessionType = PomodoroSessionType.shortBreak;
        nextCycle = currentCycle + 1;
        nextCompletedCycles = completedCycles;
        nextSessionDuration = preset.shortBreak;
      }
    } else {
      // Break over, move to next focus session
      nextSessionType = PomodoroSessionType.focus;
      nextCycle = currentCycle;
      nextCompletedCycles = completedCycles;
      nextSessionDuration = preset.focus;
    }

    return copyWith(
      currentSessionType: nextSessionType,
      currentCycle: nextCycle,
      completedCycles: nextCompletedCycles,
      sessionDuration: nextSessionDuration,
      remainingTime: nextSessionDuration,
      isRunning: false,
      sessionStartTime: DateTime.now(),
    );
  }

  // Update remaining time
  PomodoroSession updateRemainingTime(Duration remaining) {
    return copyWith(remainingTime: remaining);
  }

  // Get name of the session
  String get sessionTypeName {
    switch (currentSessionType) {
      case PomodoroSessionType.focus:
        return 'Focus';
      case PomodoroSessionType.shortBreak:
        return 'Short Break';
      case PomodoroSessionType.longBreak:
        return 'Long Break';
    }
  }

  // Get session description
  String get sessionTypeDescription {
    switch (currentSessionType) {
      case PomodoroSessionType.focus:
        return 'Focus Session $currentCycle/${preset.longBreakAfterCycles}';
      case PomodoroSessionType.shortBreak:
        return 'Short Break';
      case PomodoroSessionType.longBreak:
        return 'Long Break - Cycle $completedCycles Completed';
    }
  }

  // Get progress percentage
  double get progressPercentage {
    if (sessionDuration.inSeconds == 0) return 0.0;
    final elapsed = sessionDuration.inSeconds - remainingTime.inSeconds;
    return (elapsed / sessionDuration.inSeconds).clamp(0.0, 1.0);
  }

  // Check if this a quick session that is not part of the preset
  bool get isQuickSession => preset.id == 'quick_session';

  PomodoroSession copyWith({
    PomodoroPreset? preset,
    PomodoroSessionType? currentSessionType,
    int? currentCycle,
    int? completedCycles,
    Duration? sessionDuration,
    Duration? remainingTime,
    bool? isRunning,
    DateTime? sessionStartTime,
    DateTime? sessionEndTime,
    String? topicId,
    String? topicName,
  }) {
    return PomodoroSession(
      preset: preset ?? this.preset,
      currentSessionType: currentSessionType ?? this.currentSessionType,
      currentCycle: currentCycle ?? this.currentCycle,
      completedCycles: completedCycles ?? this.completedCycles,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      remainingTime: remainingTime ?? this.remainingTime,
      isRunning: isRunning ?? this.isRunning,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      sessionEndTime: sessionEndTime ?? this.sessionEndTime,
      topicId: topicId ?? this.topicId,
      topicName: topicName ?? this.topicName,
    );
  }

  @override
  String toString() {
    return 'PomodoroSession(preset: ${preset.name}, currentSessionType: $currentSessionType, currentCycle: $currentCycle, completedCycles: $completedCycles, remainingTime: $remainingTime, isRunning: $isRunning)';
  }
}
