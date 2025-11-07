class PomodoroPreset {
  final String id;
  final String name;
  final String description;
  final Duration focus;
  final Duration shortBreak;
  final Duration longBreak;
  final int longBreakAfterCycles;
  final bool isRecommended;
  final bool isCustom;

  const PomodoroPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.focus,
    required this.shortBreak,
    required this.longBreak,
    required this.longBreakAfterCycles,
    this.isRecommended = false,
    this.isCustom = false,
  });

  static const PomodoroPreset classic = PomodoroPreset(
    id: 'classic',
    name: '25/5 Method',
    description: 'The original 25/5 method - perfect for beginners',
    focus: Duration(minutes: 25),
    shortBreak: Duration(minutes: 5),
    longBreak: Duration(minutes: 25),
    longBreakAfterCycles: 4,
    isRecommended: true,
  );
  static const PomodoroPreset deepWork = PomodoroPreset(
    id: 'deep_work',
    name: '50/10 Method',
    description: 'Longer focus sessions for deep work',
    focus: Duration(minutes: 50),
    shortBreak: Duration(minutes: 10),
    longBreak: Duration(minutes: 20),
    longBreakAfterCycles: 4,
  );
  static const PomodoroPreset flowSate = PomodoroPreset(
    id: 'flow_state',
    name: '90/20 Method',
    description: 'Extended sessions for flow state tasks',
    focus: Duration(minutes: 90),
    shortBreak: Duration(minutes: 20),
    longBreak: Duration(minutes: 30),
    longBreakAfterCycles: 3,
  );
  static const PomodoroPreset micro = PomodoroPreset(
    id: 'micro',
    name: '15/3 Micro-Pomodoro',
    description: 'Short sessions for kids or procrastination',
    focus: Duration(minutes: 15),
    shortBreak: Duration(minutes: 3),
    longBreak: Duration(minutes: 10),
    longBreakAfterCycles: 4,
  );
  // Presets list
  static const List<PomodoroPreset> allPresets = [
    classic,
    deepWork,
    flowSate,
    micro,
  ];
  // Custom timer
  factory PomodoroPreset.custom({
    required Duration focus,
    required Duration shortBreak,
    required Duration longBreak,
    required int longBreakAfterCycles,
  }) {
    return PomodoroPreset(
      id: 'custom',
      name: 'Custom',
      description: 'Your custom timer settings',
      focus: focus,
      shortBreak: shortBreak,
      longBreak: longBreak,
      longBreakAfterCycles: longBreakAfterCycles,
      isCustom: true,
    );
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PomodoroPreset &&
        other.id == id &&
        other.focus == focus &&
        other.shortBreak == shortBreak &&
        other.longBreak == longBreak &&
        other.longBreakAfterCycles == longBreakAfterCycles;
  }

  @override
  int get hashCode =>
      Object.hash(id, focus, shortBreak, longBreak, longBreakAfterCycles);
}
