import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/timer/timer_controller.dart';
import 'features/timer/timer_state.dart';
import 'features/timer/timer_mode_screen.dart';
import 'features/timer/pomodoro_session.dart';
import 'features/progression/progression_controller.dart';
import 'features/progression/progression_model.dart';
import 'features/progression/martial_rank.dart';
import 'features/progression/progression_celebration_service.dart';
import 'features/achievements/achievement_service.dart';
import 'features/achievements/achievement_model.dart';
import 'widgets/celebration_screen.dart';
import 'features/statistics/stats_controller.dart';
import 'features/auth/user_model.dart';
import 'features/auth/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/progression_header.dart';
import 'features/timer/widgets/circular_timer.dart';
import 'features/timer/widgets/timer_stop_button.dart';
import 'features/timer/widgets/timer_character.dart';
import 'widgets/task_list.dart';
import 'package:go_router/go_router.dart';

final characterUserStreamProvider = StreamProvider.family<UserModel?, String>((
  ref,
  uid,
) {
  final userRepository = UserRepository();
  return userRepository.streamUser(uid);
});

// Provider to track shown achievement IDs across widget rebuilds
class ShownAchievementIds {
  final Set<String> _ids = <String>{};

  void add(String id) {
    _ids.add(id);
  }

  void remove(String id) {
    _ids.remove(id);
  }

  void clear() {
    _ids.clear();
  }

  bool contains(String id) => _ids.contains(id);

  int get length => _ids.length;

  Set<String> get ids => Set<String>.from(_ids);
}

final shownAchievementIdsProvider = Provider<ShownAchievementIds>((ref) {
  return ShownAchievementIds();
});

// Provider to track shown celebrations across widget rebuilds
class ShownCelebrations {
  final Set<String> _keys = <String>{};

  void add(String key) {
    _keys.add(key);
  }

  void remove(String key) {
    _keys.remove(key);
  }

  void clear() {
    _keys.clear();
  }

  bool contains(String key) => _keys.contains(key);
}

final shownCelebrationsProvider = Provider<ShownCelebrations>((ref) {
  return ShownCelebrations();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final String _currentTimerMode = "25/5 Method";
  final bool _isFocusMode = true;
  bool _weeklyGoalCelebrationShown = false;
  bool _showingAchievementDialog = false;

  @override
  void initState() {
    super.initState();
    // Note: Auth state clearing for shown achievements is handled in router.dart
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerControllerProvider);
    final weeklyStats = ref.watch(weeklyStatsProvider);
    final currentUser = FirebaseAuth.instance.currentUser;
    final userAsync = currentUser != null
        ? ref.watch(characterUserStreamProvider(currentUser.uid))
        : const AsyncValue<UserModel?>.data(null);
    final progressionAsync = currentUser != null
        ? ref.watch(userProgressionStreamProvider(currentUser.uid))
        : const AsyncValue<ProgressionModel>.data(
            ProgressionModel(
              level: 1,
              xp: 0,
              totalSessions: 0,
              rank: MartialRank.novice,
            ),
          );

    // Handle celebrations - only show once per celebration
    final shownCelebrations = ref.read(shownCelebrationsProvider);
    if (timerState.celebration != null) {
      // Create a unique key for this celebration
      final celebration = timerState.celebration!;
      final celebrationKey = celebration.newRank != null
          ? '${celebration.type}_${celebration.newLevel}_${celebration.newRank}'
          : celebration.unlockedBackground != null
          ? '${celebration.type}_${celebration.newLevel}_bg${celebration.unlockedBackground}'
          : '${celebration.type}_${celebration.newLevel}';

      if (!shownCelebrations.contains(celebrationKey)) {
        // Mark as shown IMMEDIATELY to prevent duplicate shows on rebuild
        shownCelebrations.add(celebrationKey);

        // Store celebration before clearing state
        final celebrationToShow = celebration;

        // Defer clearing to after this frame to avoid modifying provider during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(timerControllerProvider.notifier).clearCelebration();
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            debugPrint(
              'Widget not mounted in postFrameCallback, skipping celebration',
            );
            // Remove from shown set if we can't show it
            shownCelebrations.remove(celebrationKey);
            return;
          }

          // Add a delay to ensure the widget tree is fully built and stable
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) {
              debugPrint(
                'Widget not mounted after delay, skipping celebration',
              );
              shownCelebrations.remove(celebrationKey);
              return;
            }

            // Double-check context is still valid
            if (!context.mounted) {
              debugPrint('Context not mounted after delay');
              shownCelebrations.remove(celebrationKey);
              return;
            }

            try {
              debugPrint(
                'Showing celebration: ${celebrationToShow.type}, Level ${celebrationToShow.newLevel}',
              );
              ProgressionCelebrationService.showCelebration(
                context,
                celebrationToShow,
              );
            } catch (e, stackTrace) {
              debugPrint('Error showing celebration: $e');
              debugPrint('Stack trace: $stackTrace');
              // Remove from shown set on error so it can be retried
              shownCelebrations.remove(celebrationKey);
            }
          });
        });
      }
    }

    // Handle achievement celebrations - only show once per achievement
    final shownAchievementIds = ref.read(shownAchievementIdsProvider);
    if (timerState.achievementCelebrations != null &&
        timerState.achievementCelebrations!.isNotEmpty &&
        !_showingAchievementDialog) {
      // Filter out achievements that have already been shown
      final achievementsToShow = timerState.achievementCelebrations!
          .where((achievement) => !shownAchievementIds.contains(achievement.id))
          .toList();

      if (achievementsToShow.isNotEmpty) {
        debugPrint(
          'Home screen - new achievement celebrations detected: ${achievementsToShow.length} achievements (total in state: ${timerState.achievementCelebrations!.length}, already shown: ${shownAchievementIds.length})',
        );

        // Validate achievements before showing
        final validAchievements = achievementsToShow.where((a) {
          final isValid = a.name.isNotEmpty && a.description.isNotEmpty;
          if (!isValid) {
            debugPrint('Invalid achievement found: ${a.id}');
          }
          return isValid;
        }).toList();

        if (validAchievements.isNotEmpty) {
          // Mark these achievements as shown immediately in provider
          for (final achievement in validAchievements) {
            shownAchievementIds.add(achievement.id);
            debugPrint('Marked achievement ${achievement.id} as shown');
          }

          // Store achievements to show before clearing state (create a copy)
          final achievementsToDisplay = List<AchievementModel>.from(
            validAchievements,
          );

          // Mark that we're currently showing to avoid repeated dialogs on rebuild
          _showingAchievementDialog = true;

          // Defer clearing to after this frame to avoid modifying provider during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(timerControllerProvider.notifier)
                .clearAchievementCelebrations();
            debugPrint('Cleared achievement celebrations state (post-frame)');
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              debugPrint(
                'Widget not mounted in postFrameCallback, skipping achievement celebrations',
              );
              return;
            }

            // Add a delay to ensure the widget tree is fully built and stable
            Future.delayed(const Duration(milliseconds: 500), () {
              if (!mounted) {
                debugPrint(
                  'Widget not mounted after delay, skipping achievement celebrations',
                );
                return;
              }

              // Double-check context is still valid
              if (!context.mounted) {
                debugPrint('Context not mounted after delay');
                return;
              }

              try {
                debugPrint(
                  'Showing achievement celebrations dialog for ${achievementsToDisplay.length} achievements',
                );

                // Show achievements - state is already cleared and IDs marked as shown
                AchievementService.showAchievementCelebrations(
                  context,
                  achievementsToDisplay,
                  onAllShown: () {
                    // Allow future achievement dialogs
                    _showingAchievementDialog = false;
                    // Ensure state is cleared as a final safeguard
                    Future.microtask(() {
                      ref
                          .read(timerControllerProvider.notifier)
                          .clearAchievementCelebrations();
                    });
                  },
                );
              } catch (e, stackTrace) {
                debugPrint('Error showing achievement celebrations: $e');
                debugPrint('Stack trace: $stackTrace');
                // Remove from shown set on error so they can be retried
                for (final achievement in achievementsToDisplay) {
                  shownAchievementIds.remove(achievement.id);
                }
                _showingAchievementDialog = false;
              }
            });
          });
        } else {
          // No valid achievements, clear state
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(timerControllerProvider.notifier)
                .clearAchievementCelebrations();
          });
        }
      } else {
        // All achievements have already been shown, clear state silently
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(timerControllerProvider.notifier)
              .clearAchievementCelebrations();
        });
      }
    }

    final shouldShowWeeklyGoalCelebration =
        timerState.weeklyGoalCompleted == true && !_weeklyGoalCelebrationShown;

    // Reduce noisy logs that can print every rebuild (timer ticks)
    if (shouldShowWeeklyGoalCelebration) {
      debugPrint(
        'Weekly goal - ready to show (completed=${timerState.weeklyGoalCompleted})',
      );
    }

    if (shouldShowWeeklyGoalCelebration) {
      debugPrint('Weekly goal celebration triggered in home screen');
      _weeklyGoalCelebrationShown = true;

      // Store the celebration state before clearing
      final celebrationToShow = timerState.weeklyGoalCompleted;

      // Defer clearing to after this frame to avoid modifying provider during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(timerControllerProvider.notifier).clearWeeklyGoalCelebration();
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && context.mounted && celebrationToShow == true) {
          debugPrint('Showing weekly goal celebration dialog');
          _showWeeklyGoalCelebration(context);
        } else {
          debugPrint(
            'Widget not mounted or celebration state changed, skipping celebration',
          );
          _weeklyGoalCelebrationShown = false;
        }
      });
    }

    if (timerState.weeklyGoalCompleted == null) {
      _weeklyGoalCelebrationShown = false;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Header
                      userAsync.when(
                        data: (userModel) => progressionAsync.when(
                          data: (progression) => ProgressionHeader(
                            progression: progression,
                            flames: weeklyStats.when(
                              data: (stats) => stats.streakDays,
                              loading: () => userModel?.streak ?? 0,
                              error: (_, _) => userModel?.streak ?? 0,
                            ),
                          ),
                          loading: () => ProgressionHeader(
                            progression: const ProgressionModel(
                              level: 1,
                              xp: 0,
                              totalSessions: 0,
                              rank: MartialRank.novice,
                            ),
                            flames: userModel?.streak ?? 0,
                          ),
                          error: (_, _) => ProgressionHeader(
                            progression: const ProgressionModel(
                              level: 1,
                              xp: 0,
                              totalSessions: 0,
                              rank: MartialRank.novice,
                            ),
                            flames: userModel?.streak ?? 0,
                          ),
                        ),
                        loading: () => ProgressionHeader(
                          progression: const ProgressionModel(
                            level: 1,
                            xp: 0,
                            totalSessions: 0,
                            rank: MartialRank.novice,
                          ),
                          flames: 0,
                        ),
                        error: (_, _) => ProgressionHeader(
                          progression: const ProgressionModel(
                            level: 1,
                            xp: 0,
                            totalSessions: 0,
                            rank: MartialRank.novice,
                          ),
                          flames: 0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Timer section with circular timer, stop button, and character
                      SizedBox(
                        width: 350,
                        height: 360,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Circular timer positioned at top center (moved lower to show glow)
                            Positioned(
                              top: 24,
                              child: progressionAsync.when(
                                data: (progression) => RepaintBoundary(
                                  child: CircularTimer(
                                    totalDuration: timerState.totalDuration,
                                    remaining: timerState.remaining,
                                    isRunning: timerState.isRunning,
                                    isPaused: timerState.isPaused,
                                    isFocusMode: _isFocusMode,
                                    sessionLabel: _getCachedSessionTypeText(
                                      timerState,
                                    ),
                                    rank: progression.rank,
                                  ),
                                ),
                                loading: () => RepaintBoundary(
                                  child: CircularTimer(
                                    totalDuration: timerState.totalDuration,
                                    remaining: timerState.remaining,
                                    isRunning: timerState.isRunning,
                                    isPaused: timerState.isPaused,
                                    isFocusMode: _isFocusMode,
                                    sessionLabel: _getCachedSessionTypeText(
                                      timerState,
                                    ),
                                    rank: null,
                                  ),
                                ),
                                error: (_, _) => RepaintBoundary(
                                  child: CircularTimer(
                                    totalDuration: timerState.totalDuration,
                                    remaining: timerState.remaining,
                                    isRunning: timerState.isRunning,
                                    isPaused: timerState.isPaused,
                                    isFocusMode: _isFocusMode,
                                    sessionLabel: _getCachedSessionTypeText(
                                      timerState,
                                    ),
                                    rank: null,
                                  ),
                                ),
                              ),
                            ),
                            // Stop button positioned outside the circle in top right
                            Positioned(
                              top: 0,
                              right: 0,
                              child: TimerStopButton(
                                onStop: () {
                                  ref
                                      .read(timerControllerProvider.notifier)
                                      .stop();
                                },
                                isVisible:
                                    timerState.isRunning ||
                                    timerState.totalDuration > Duration.zero,
                              ),
                            ),
                            // Character image positioned at the bottom in front of timer
                            Positioned(
                              bottom: -8,
                              child: progressionAsync.when(
                                data: (progression) => RepaintBoundary(
                                  child: TimerCharacter(
                                    timerState: timerState,
                                    rank: progression.rank,
                                  ),
                                ),
                                loading: () {
                                  // Use user data to calculate rank while progression loads to avoid flash
                                  return userAsync.maybeWhen(
                                    data: (userModel) {
                                      if (userModel != null) {
                                        final tempProgression =
                                            ProgressionModel.fromStats(
                                              userModel.xp,
                                              userModel.totalSessions,
                                            );
                                        return RepaintBoundary(
                                          child: TimerCharacter(
                                            timerState: timerState,
                                            rank: tempProgression.rank,
                                          ),
                                        );
                                      }
                                      return const SizedBox(
                                        width: 200,
                                        height: 200,
                                      );
                                    },
                                    orElse: () =>
                                        const SizedBox(width: 200, height: 200),
                                  );
                                },
                                error: (_, _) {
                                  // Use user data to calculate rank on error to avoid flash
                                  return userAsync.maybeWhen(
                                    data: (userModel) {
                                      if (userModel != null) {
                                        final tempProgression =
                                            ProgressionModel.fromStats(
                                              userModel.xp,
                                              userModel.totalSessions,
                                            );
                                        return RepaintBoundary(
                                          child: TimerCharacter(
                                            timerState: timerState,
                                            rank: tempProgression.rank,
                                          ),
                                        );
                                      }
                                      return const SizedBox(
                                        width: 200,
                                        height: 200,
                                      );
                                    },
                                    orElse: () =>
                                        const SizedBox(width: 200, height: 200),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Focus Shield chip
                      _buildFocusShieldChip(),
                      const SizedBox(height: 16),
                      // Timer mode
                      _buildTimerModeCard(),
                      const SizedBox(height: 24),
                      // Tasks preview
                      _buildTasksPreview(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerModeCard() {
    final theme = Theme.of(context);
    final selectionState = ref.watch(timerModeSelectionProvider);
    final String modeLabel = selectionState.selectedCustom
        ? 'Custom • Focus ${selectionState.customFocus.inMinutes}m • Short ${selectionState.customShortBreak.inMinutes}m • Long ${selectionState.customLongBreak.inMinutes}m • ${selectionState.customCycles} cycles'
        : selectionState.selectedPreset?.name ??
              (selectionState.selectedQuickSession != null
                  ? '${selectionState.selectedQuickSession} min session'
                  : _currentTimerMode);
    return GestureDetector(
      onTap: () => _showTimerModeSelector(context),
      child: Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.tune,
                  color: theme.colorScheme.onSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timer mode',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      modeLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.onSurface,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasksPreview() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your tasks',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/tasks'),
              child: const Text('Open'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TaskList(limit: 5, onViewAll: () => context.go('/tasks')),
        const SizedBox(height: 24),
      ],
    );
  }

  String _getSessionTypeText(TimerState timerState) {
    if (timerState.isPomodoroMode && timerState.pomodoroSession != null) {
      final pomodoroSession = timerState.pomodoroSession!;

      // For focus sessions, show cycle count if there are cycles
      if (pomodoroSession.currentSessionType == PomodoroSessionType.focus) {
        // Only show cycle count if there are multiple cycles (longBreakAfterCycles > 1)
        if (pomodoroSession.preset.longBreakAfterCycles > 1) {
          return 'Focus Session ${pomodoroSession.currentCycle}/${pomodoroSession.preset.longBreakAfterCycles}';
        } else {
          return 'Focus Session';
        }
      }

      // For breaks, use the session type name
      return pomodoroSession.sessionTypeName;
    }

    // Quick session (not Pomodoro mode) - just show "Focus Session" without cycle count
    return "Focus Session";
  }

  // Memoized session label - cache based on key properties
  String? _cachedSessionLabel;
  int? _cachedTotalMinutes;
  bool? _cachedIsPomodoro;
  String? _cachedSessionTypeName;
  int? _cachedCurrentCycle;
  int? _cachedLongBreakAfterCycles;

  String _getCachedSessionTypeText(TimerState timerState) {
    // Only recalculate if relevant properties changed
    final totalMinutes = timerState.totalDuration.inMinutes;
    final isPomodoro = timerState.isPomodoroMode;
    final sessionTypeName = timerState.pomodoroSession?.sessionTypeName;
    final currentCycle = timerState.pomodoroSession?.currentCycle;
    final longBreakAfterCycles =
        timerState.pomodoroSession?.preset.longBreakAfterCycles;

    if (_cachedTotalMinutes == totalMinutes &&
        _cachedIsPomodoro == isPomodoro &&
        _cachedSessionTypeName == sessionTypeName &&
        _cachedCurrentCycle == currentCycle &&
        _cachedLongBreakAfterCycles == longBreakAfterCycles &&
        _cachedSessionLabel != null) {
      return _cachedSessionLabel!;
    }
    _cachedTotalMinutes = totalMinutes;
    _cachedIsPomodoro = isPomodoro;
    _cachedSessionTypeName = sessionTypeName;
    _cachedCurrentCycle = currentCycle;
    _cachedLongBreakAfterCycles = longBreakAfterCycles;
    _cachedSessionLabel = _getSessionTypeText(timerState);
    return _cachedSessionLabel!;
  }

  void _showTimerModeSelector(BuildContext context) {
    context.go('/timer-mode');
  }

  void _showWeeklyGoalCelebration(BuildContext context) {
    final theme = Theme.of(context);
    CelebrationHelper.showAchievement(
      context,
      title: 'Weekly Goal Completed! 🎉',
      subtitle: 'Amazing Work!',
      description:
          'You\'ve completed your weekly goal. Keep up the fantastic momentum!',
      icon: Icons.emoji_events,
      color: theme.colorScheme.primary,
      buttonText: 'Continue',
      onContinue: () {
        Navigator.of(context, rootNavigator: true).pop();
      },
    );
  }

  Widget _buildFocusShieldChip() {
    // Access focusShieldActive from controller
    final timerController = ref.read(timerControllerProvider.notifier);

    // Only show chip when Focus Shield is active
    if (!timerController.focusShieldActive) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              'Focus Shield',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
