import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'timer_controller.dart';
import 'pomodoro_presets.dart';
import '../../widgets/preset_card.dart';
import '../achievements/achievement_tracking_service.dart';

// Provider to manage timer mode selection state
final timerModeSelectionProvider =
    NotifierProvider<TimerModeSelectionNotifier, TimerModeSelectionState>(() {
      return TimerModeSelectionNotifier();
    });

class TimerModeSelectionNotifier extends Notifier<TimerModeSelectionState> {
  @override
  TimerModeSelectionState build() {
    // Start with default, then try to hydrate from onboarding selection
    final initial = TimerModeSelectionState.initial();
    _hydrateFromOnboardingSelection();
    return initial;
  }

  Future<void> _hydrateFromOnboardingSelection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selected = prefs.getString('selected_preset');
      if (selected == null) return;

      final mapped = _mapOnboardingNameToPreset(selected);
      if (mapped != null) {
        state = state.copyWith(
          selectedPreset: mapped,
          selectedQuickSession: null,
          selectedCustom: false,
        );
      }
    } catch (_) {
      // Ignore and keep defaults
    }
  }

  PomodoroPreset? _mapOnboardingNameToPreset(String name) {
    switch (name.trim()) {
      case '25/5':
        return PomodoroPreset.classic;
      case '50/10':
        return PomodoroPreset.deepWork;
      case '90/20':
        return PomodoroPreset.flowSate;
      case '15/3':
        return PomodoroPreset.micro;
      default:
        // Also try to match by minutes in format "X/Y"
        final parts = name.split('/');
        if (parts.length == 2) {
          final focus = int.tryParse(parts[0]);
          final brk = int.tryParse(parts[1]);
          if (focus == 25 && brk == 5) return PomodoroPreset.classic;
          if (focus == 50 && brk == 10) return PomodoroPreset.deepWork;
          if (focus == 90 && brk == 20) return PomodoroPreset.flowSate;
          if (focus == 15 && brk == 3) return PomodoroPreset.micro;
        }
        return null;
    }
  }

  void selectPreset(PomodoroPreset preset) {
    state = TimerModeSelectionState(
      selectedPreset: preset,
      selectedQuickSession: null,
      selectedCustom: false,
    );
  }

  void selectQuickSession(int minutes) {
    state = TimerModeSelectionState(
      selectedPreset: null,
      selectedQuickSession: minutes,
      selectedCustom: false,
    );
  }

  void selectCustom() {
    state = const TimerModeSelectionState(
      selectedPreset: null,
      selectedQuickSession: null,
      selectedCustom: true,
    );
  }

  // Custom value setters
  void setCustomFocusMinutes(int minutes) {
    state = state.copyWith(customFocus: Duration(minutes: minutes));
  }

  void setCustomShortBreakMinutes(int minutes) {
    state = state.copyWith(customShortBreak: Duration(minutes: minutes));
  }

  void setCustomLongBreakMinutes(int minutes) {
    state = state.copyWith(customLongBreak: Duration(minutes: minutes));
  }

  void setCustomCycles(int cycles) {
    state = state.copyWith(customCycles: cycles);
  }

  void clearSelection() {
    state = TimerModeSelectionState.initial();
  }

  bool get canStartTimer {
    // Always true since we now have a default recommended preset
    return true;
  }

  Future<void> startSelectedTimer(WidgetRef ref) async {
    // Starting selected timer

    // No need to check canStartTimer since we always have a default now

    final timerController = ref.read(timerControllerProvider.notifier);

    if (state.selectedQuickSession != null) {
      // Start a quick session
      timerController.start(Duration(minutes: state.selectedQuickSession!));
      // Quick session started
    } else if (state.selectedPreset != null) {
      // Start a pomodoro session
      timerController.startPomodoro(state.selectedPreset!);
      // Pomodoro session started
    } else if (state.selectedCustom) {
      // Build a custom preset from current custom values
      final preset = PomodoroPreset.custom(
        focus: state.customFocus,
        shortBreak: state.customShortBreak,
        longBreak: state.customLongBreak,
        longBreakAfterCycles: state.customCycles,
      );
      // Starting custom pomodoro

      // Track custom duration usage for achievements
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final trackingService = AchievementTrackingService();
        await trackingService.trackCustomDurationUsage(currentUser.uid);
      }

      timerController.startPomodoro(preset);
      // Custom Pomodoro session started
    } else {
      // Fallback to recommended preset if somehow no selection is made
      timerController.startPomodoro(PomodoroPreset.classic);
      // Recommended preset started
    }

    // Keep selection so Home can display current mode until user changes it
  }
}

class TimerModeSelectionState {
  final PomodoroPreset? selectedPreset;
  final int? selectedQuickSession;
  final bool selectedCustom;
  final Duration customFocus;
  final Duration customShortBreak;
  final Duration customLongBreak;
  final int customCycles;

  const TimerModeSelectionState({
    this.selectedPreset,
    this.selectedQuickSession,
    this.selectedCustom = false,
    this.customFocus = const Duration(minutes: 25),
    this.customShortBreak = const Duration(minutes: 5),
    this.customLongBreak = const Duration(minutes: 15),
    this.customCycles = 4,
  });

  factory TimerModeSelectionState.initial() {
    return const TimerModeSelectionState(
      selectedPreset: PomodoroPreset.classic, // Default to recommended preset
      selectedQuickSession: null,
      selectedCustom: false,
      customFocus: Duration(minutes: 25),
      customShortBreak: Duration(minutes: 5),
      customLongBreak: Duration(minutes: 15),
      customCycles: 4,
    );
  }

  TimerModeSelectionState copyWith({
    PomodoroPreset? selectedPreset,
    int? selectedQuickSession,
    bool? selectedCustom,
    Duration? customFocus,
    Duration? customShortBreak,
    Duration? customLongBreak,
    int? customCycles,
  }) {
    return TimerModeSelectionState(
      selectedPreset: selectedPreset ?? this.selectedPreset,
      selectedQuickSession: selectedQuickSession ?? this.selectedQuickSession,
      selectedCustom: selectedCustom ?? this.selectedCustom,
      customFocus: customFocus ?? this.customFocus,
      customShortBreak: customShortBreak ?? this.customShortBreak,
      customLongBreak: customLongBreak ?? this.customLongBreak,
      customCycles: customCycles ?? this.customCycles,
    );
  }
}

class TimerModeSelectionScreen extends ConsumerStatefulWidget {
  const TimerModeSelectionScreen({super.key});

  @override
  ConsumerState<TimerModeSelectionScreen> createState() =>
      _TimerModeSelectionScreenState();
}

class _TimerModeSelectionScreenState
    extends ConsumerState<TimerModeSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          'Choose timer mode',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtitle
            Text(
              'Choose from our recommended presets or create your own custom timer.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              overflow: TextOverflow.visible,
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // Recommended Section
            _buildSectionHeader(
              'Recommended',
              Icons.star,
              theme.colorScheme.secondary,
              theme,
            ),
            const SizedBox(height: 16),
            _buildPresetCard(
              PomodoroPreset.classic.name,
              PomodoroPreset.classic.description,
              'RECOMMENDED',
              PomodoroPreset.classic,
              isRecommended: true,
              theme: theme,
            ),
            const SizedBox(height: 32),

            // Alternative Methods Section
            _buildSectionHeader(
              'Alternative methods',
              Icons.settings,
              theme.colorScheme.primary,
              theme,
            ),
            const SizedBox(height: 16),
            _buildPresetCard(
              PomodoroPreset.deepWork.name,
              PomodoroPreset.deepWork.description,
              null,
              PomodoroPreset.deepWork,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildPresetCard(
              PomodoroPreset.flowSate.name,
              PomodoroPreset.flowSate.description,
              null,
              PomodoroPreset.flowSate,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildPresetCard(
              PomodoroPreset.micro.name,
              PomodoroPreset.micro.description,
              null,
              PomodoroPreset.micro,
              theme: theme,
            ),
            const SizedBox(height: 32),

            // Custom Mode Section
            _buildSectionHeader(
              'Custom mode',
              Icons.settings,
              theme.colorScheme.primary,
              theme,
            ),
            const SizedBox(height: 16),
            _buildPresetCard(
              'Custom Timer',
              'Set your own focus, break, and cycle settings',
              null,
              null, // Custom preset
              isCustom: true,
              theme: theme,
            ),
            const SizedBox(height: 12),
            // Inline custom controls when custom is selected
            if (ref.watch(timerModeSelectionProvider).selectedCustom)
              _buildCustomControls(theme),
            const SizedBox(height: 32),

            // Quick Sessions Section
            _buildSectionHeader(
              'Quick sessions',
              Icons.flash_on,
              theme.colorScheme.secondary,
              theme,
            ),
            const SizedBox(height: 16),
            _buildQuickSessionsGrid(theme),
            const SizedBox(height: 100), // Space for bottom navigation
          ],
        ),
      ),
    );
  }

  Widget _buildCustomControls(ThemeData theme) {
    final selectionState = ref.watch(timerModeSelectionProvider);
    final selectionNotifier = ref.read(timerModeSelectionProvider.notifier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomSliderRow(
            theme: theme,
            label: 'Focus',
            minutes: selectionState.customFocus.inMinutes,
            min: 5,
            max: 120,
            onChanged: (v) => selectionNotifier.setCustomFocusMinutes(v),
          ),
          const SizedBox(height: 12),
          _buildCustomSliderRow(
            theme: theme,
            label: 'Short break',
            minutes: selectionState.customShortBreak.inMinutes,
            min: 1,
            max: 30,
            onChanged: (v) => selectionNotifier.setCustomShortBreakMinutes(v),
          ),
          const SizedBox(height: 12),
          _buildCustomSliderRow(
            theme: theme,
            label: 'Long break',
            minutes: selectionState.customLongBreak.inMinutes,
            min: 5,
            max: 60,
            onChanged: (v) => selectionNotifier.setCustomLongBreakMinutes(v),
          ),
          const SizedBox(height: 12),
          _buildCustomCyclesRow(
            theme: theme,
            cycles: selectionState.customCycles,
            min: 2,
            max: 8,
            onChanged: (v) => selectionNotifier.setCustomCycles(v),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomSliderRow({
    required ThemeData theme,
    required String label,
    required int minutes,
    required int min,
    required int max,
    required void Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Text('$minutes min', style: theme.textTheme.labelMedium),
          ],
        ),
        Slider(
          value: minutes.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: (max - min),
          label: '$minutes',
          onChanged: (v) => onChanged(v.round()),
          activeColor: theme.colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildCustomCyclesRow({
    required ThemeData theme,
    required int cycles,
    required int min,
    required int max,
    required void Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Cycles until long break',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Text('$cycles cycles', style: theme.textTheme.labelMedium),
          ],
        ),
        Slider(
          value: cycles.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: (max - min),
          label: '$cycles',
          onChanged: (v) => onChanged(v.round()),
          activeColor: theme.colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetCard(
    String title,
    String description,
    String? tag,
    PomodoroPreset? preset, {
    bool isRecommended = false,
    bool isCustom = false,
    required ThemeData theme,
  }) {
    final selectionState = ref.watch(timerModeSelectionProvider);
    final selectionNotifier = ref.read(timerModeSelectionProvider.notifier);
    final isSelected = isCustom
        ? selectionState.selectedCustom
        : selectionState.selectedPreset == preset;

    return PresetCard(
      title: title,
      description: description,
      tag: tag,
      preset: preset,
      isSelected: isSelected,
      isRecommended: isRecommended,
      isCustom: isCustom,
      onTap: () {
        if (preset != null) {
          selectionNotifier.selectPreset(preset);
          // Show feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected: ${preset.name}'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (isCustom) {
          selectionNotifier.selectCustom();
        }
      },
    );
  }

  Widget _buildQuickSessionsGrid(ThemeData theme) {
    final quickSessions = [10, 15, 20, 30, 45, 60];
    final selectionState = ref.watch(timerModeSelectionProvider);
    final selectionNotifier = ref.read(timerModeSelectionProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use 1 column on very small screens, 2 on normal phones, 3+ on tablets
        final width = constraints.maxWidth;
        int columns = 2;
        if (width < 320) {
          columns = 1;
        } else if (width > 720) {
          columns = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: quickSessions.length,
          itemBuilder: (context, index) {
            final minutes = quickSessions[index];
            final isSelected = selectionState.selectedQuickSession == minutes;

            return GestureDetector(
              onTap: () {
                selectionNotifier.selectQuickSession(minutes);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$minutes min',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quick focus',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
