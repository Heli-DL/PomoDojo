import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'dart:async';
import 'timer_state.dart';
import 'pomodoro_presets.dart';
import 'pomodoro_session.dart';
import 'session_model.dart';
import 'session_repository.dart';
import '../progression/progression_controller.dart';
import '../progression/weekly_goal_service.dart';
import '../achievements/achievement_service.dart';
import '../achievements/achievement_calculator.dart';
import '../achievements/achievement_tracking_service.dart';
import '../topics/topic_controller.dart';
import '../statistics/stats_controller.dart';
import '../tasks/task_session_service.dart';
import '../../core/focus_shield/focus_shield_channel.dart';
import '../../core/notifications/notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:android_intent_plus/android_intent.dart';

class TimerController extends StateNotifier<TimerState> {
  final Ref _ref;

  TimerController(this._ref) : super(TimerState.initial()) {
    _startTicker();
    _initializeSettings();
    _listenNotificationActions();
  }

  Future<void> _initializeSettings() async {
    await _loadFocusShieldSettings();
    await _scheduleStreakReminderIfNeeded();
  }

  Timer? _ticker;
  DateTime? _sessionStartAt;
  final TaskSessionService _taskSessionService = TaskSessionService();
  final AchievementTrackingService _trackingService =
      AchievementTrackingService();
  final WeeklyGoalService _weeklyGoalService = WeeklyGoalService();

  // Focus Shield state
  bool _focusShieldActive = false;
  bool _isCompleting = false; // prevent duplicate completion

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();
    });
  }

  // Schedule a streak reminder this evening if user has an active streak but no session today
  Future<void> _scheduleStreakReminderIfNeeded() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final currentStreak = await AchievementCalculator.calculateCurrentStreak(
        currentUser.uid,
      );
      if (currentStreak <= 0) return; // No active streak

      final dailySessions = await AchievementCalculator.calculateDailySessions(
        currentUser.uid,
      );
      if (dailySessions > 0) {
        // Already completed session today; cancel any prior reminder
        await NotificationService.cancelStreakReminder();
        return;
      }

      // Schedule for 8:00 PM local time today if in the future
      final now = DateTime.now();
      final remindAt = DateTime(now.year, now.month, now.day, 20, 0);
      if (remindAt.isAfter(now)) {
        await NotificationService.scheduleStreakReminder(remindAt);
      }
    } catch (e) {
      debugPrint('Error scheduling streak reminder: $e');
    }
  }

  // Update remaining time
  void _updateRemainingTime() {
    if (!state.isRunning || state.endAt == null) return;
    final now = DateTime.now();
    final remaining = state.endAt!.difference(now);

    if (remaining <= Duration.zero) {
      _complete();
    } else {
      state = state.copyWith(remaining: remaining);
    }
  }

  // Start timer with given duration
  void start(Duration duration) {
    final now = DateTime.now();
    final endAt = now.add(duration);
    _sessionStartAt = now;

    state = state.copyWith(
      remaining: duration,
      totalDuration: duration,
      isRunning: true,
      endAt: endAt,
      isPomodoroMode: false,
      pomodoroSession: null,
    );
    // Timer started

    // Enable Focus Shield (async, errors handled internally)
    _enableFocusShield().catchError((e) {
      debugPrint('Error enabling Focus Shield during timer start: $e');
    });

    // Schedule completion notification for quick session (always focus)
    if (state.sessionNotificationsEnabled && state.endAt != null) {
      NotificationService.scheduleSessionComplete(state.endAt!).catchError((e) {
        debugPrint('Error scheduling session complete notification: $e');
      });
    }
  }

  // Start Pomodoro session with given preset
  void startPomodoro(PomodoroPreset preset) {
    final topic = _ref.read(selectedTopicProvider);
    final pomodoroSession = PomodoroSession.initial(
      preset,
      topicId: topic?.id,
      topicName: topic?.name,
    ).start();
    final now = DateTime.now();
    final endAt = now.add(pomodoroSession.sessionDuration);

    _sessionStartAt = now;

    state = state.copyWith(
      remaining: pomodoroSession.sessionDuration,
      totalDuration: pomodoroSession.sessionDuration,
      isRunning: true,
      endAt: endAt,
      isPomodoroMode: true,
      pomodoroSession: pomodoroSession,
    );

    _enableFocusShield().catchError((e) {
      debugPrint('Error enabling Focus Shield during pomodoro start: $e');
    });

    // Schedule notification for the current session
    if (state.endAt != null) {
      final isFocus =
          state.pomodoroSession!.currentSessionType ==
          PomodoroSessionType.focus;
      if (isFocus && state.sessionNotificationsEnabled) {
        NotificationService.scheduleSessionComplete(state.endAt!).catchError((
          e,
        ) {
          debugPrint('Error scheduling session complete notification: $e');
        });
      } else if (!isFocus && state.breakNotificationsEnabled) {
        NotificationService.scheduleBreakOver(state.endAt!).catchError((e) {
          debugPrint('Error scheduling break over notification: $e');
        });
      }
    }
  }

  // Stop timer manually
  void stop() {
    state = state.copyWith(
      remaining: Duration.zero,
      isRunning: false,
      isPaused: false,
      endAt: null,
    );
    _sessionStartAt = null;

    // Disable Focus Shield and cancel notifications
    _disableFocusShield();
    NotificationService.cancelSessionComplete();
    NotificationService.cancelBreakOver();
  }

  // Pause timer
  void pause() {
    if (!state.isRunning || state.isPaused) return;

    state = state.copyWith(isRunning: false, isPaused: true);

    // Disable Focus Shield but keep notifications scheduled
    _disableFocusShield();
  }

  // Resume timer
  void resume() {
    if (!state.isPaused || state.isRunning) return;

    // Timer resumed
    final now = DateTime.now();
    final endAt = now.add(state.remaining);

    state = state.copyWith(isRunning: true, isPaused: false, endAt: endAt);
    _sessionStartAt = now;

    // Re-enable Focus Shield
    _enableFocusShield().catchError((e) {
      debugPrint('Error enabling Focus Shield during resume: $e');
    });

    // Reschedule notification for the resumed session
    if (state.endAt != null) {
      final isFocus =
          state.isPomodoroMode &&
          state.pomodoroSession?.currentSessionType ==
              PomodoroSessionType.focus;
      if (isFocus && state.sessionNotificationsEnabled) {
        NotificationService.scheduleSessionComplete(state.endAt!).catchError((
          e,
        ) {
          debugPrint('Error scheduling session complete notification: $e');
        });
      } else if (!isFocus && state.breakNotificationsEnabled) {
        NotificationService.scheduleBreakOver(state.endAt!).catchError((e) {
          debugPrint('Error scheduling break over notification: $e');
        });
      }
    }
  }

  // Complete current session
  void completeSession() {
    if (state.pomodoroSession == null) {
      debugPrint('No active Pomodoro session to complete');
      return;
    }
    final currentSession = state.pomodoroSession!;
    final completedSession = currentSession.completeSession();

    state = state.copyWith(
      remaining: completedSession.sessionDuration,
      totalDuration: completedSession.sessionDuration,
      isRunning: false,
      endAt: null,
      pomodoroSession: completedSession,
    );
  }

  void clearCelebration() {
    state = state.copyWith(celebration: null);
  }

  void clearAchievementCelebrations() {
    state = state.copyWith(achievementCelebrations: null);
  }

  void clearWeeklyGoalCelebration() {
    state = state.copyWith(weeklyGoalCompleted: null);
  }

  // Reset all celebration states (called on logout or account switch)
  void clearAllCelebrations() {
    state = state.copyWith(
      celebration: null,
      achievementCelebrations: null,
      weeklyGoalCompleted: null,
    );
    debugPrint('All celebration states cleared');
  }

  void continueSession() {
    if (state.pomodoroSession == null) {
      debugPrint('No active Pomodoro session to continue');
      return;
    }
    final pomodoroSession = state.pomodoroSession!;
    final now = DateTime.now();
    final endAt = now.add(pomodoroSession.sessionDuration);
    _sessionStartAt = now;

    state = state.copyWith(
      remaining: pomodoroSession.sessionDuration,
      totalDuration: pomodoroSession.sessionDuration,
      isRunning: true,
      endAt: endAt,
      pomodoroSession: pomodoroSession.start(),
    );

    _enableFocusShield().catchError((e) {
      debugPrint('Error enabling Focus Shield during continue: $e');
    });

    // Schedule notification for the new session
    if (state.endAt != null) {
      final isFocus =
          state.pomodoroSession!.currentSessionType ==
          PomodoroSessionType.focus;
      if (isFocus && state.sessionNotificationsEnabled) {
        NotificationService.scheduleSessionComplete(state.endAt!).catchError((
          e,
        ) {
          debugPrint('Error scheduling session complete notification: $e');
        });
      } else if (!isFocus && state.breakNotificationsEnabled) {
        NotificationService.scheduleBreakOver(state.endAt!).catchError((e) {
          debugPrint('Error scheduling break over notification: $e');
        });
      }
    }
  }

  // Complete when timer hits zero and award XP
  Future<void> _complete() async {
    if (_isCompleting) {
      return;
    }
    _isCompleting = true;
    try {
      final sessionStartAt = _sessionStartAt;

      if (sessionStartAt == null) {
        debugPrint('Session start time not recorded.');
        return;
      }

      final now = DateTime.now();
      final sessionDuration = now.difference(sessionStartAt);
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint('No authenticated user found');
        return;
      }

      // Handle session completion
      if (state.isPomodoroMode && state.pomodoroSession != null) {
        final currentType = state.pomodoroSession!.currentSessionType;
        final pomodoroDuration = state.pomodoroSession!.sessionDuration;
        final topic = _ref.read(selectedTopicProvider);

        completeSession();

        NotificationService.cancelSessionComplete();
        NotificationService.cancelBreakOver();

        if (state.sessionNotificationsEnabled) {
          try {
            await NotificationService.showSessionComplete();
          } catch (e) {
            debugPrint('Failed to show session complete notification: $e');
          }
        }

        if (currentType != PomodoroSessionType.focus &&
            state.breakNotificationsEnabled) {
          try {
            await NotificationService.showBreakOver();
          } catch (e) {
            debugPrint('Failed to show break over notification: $e');
          }
        }

        if (currentType != PomodoroSessionType.focus) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await _trackingService.trackBreakCompliance(
              uid: user.uid,
              date: DateTime.now(),
              tookBreak: true,
            );
          }
        }

        // Award XP only when a focus session completes
        if (currentType == PomodoroSessionType.focus) {
          try {
            final progressionController = _ref.read(
              progressionControllerProvider.notifier,
            );
            final previousProgression = _ref.read(
              progressionControllerProvider,
            );
            final celebration = await progressionController.awardSessionXP(
              pomodoroDuration,
            );

            if (celebration != null) {
              debugPrint(
                'Setting celebration in timer state: type=${celebration.type}, level=${celebration.newLevel}',
              );
              state = state.copyWith(celebration: celebration);
            } else {
              debugPrint('No celebration returned from awardSessionXP');
            }

            // Cancel any streak reminder since user completed a session today
            await NotificationService.cancelStreakReminder();

            await _saveSession(
              sessionStartAt: sessionStartAt,
              sessionEndAt: now,
              duration: pomodoroDuration,
              xpAwarded: pomodoroDuration.inMinutes,
              topicId: topic?.id,
              topicName: topic?.name,
              sessionType: 'focus',
            );

            final weeklyGoalCompleted = await _checkAndTrackWeeklyGoal(
              user.uid,
            );
            debugPrint(
              'Weekly goal completed check result: $weeklyGoalCompleted',
            );

            // Store weekly goal completion in state for celebration
            if (weeklyGoalCompleted) {
              debugPrint('Setting weeklyGoalCompleted state to true');
              state = state.copyWith(weeklyGoalCompleted: true);
              debugPrint(
                'State updated - weeklyGoalCompleted: ${state.weeklyGoalCompleted}',
              );
            }

            // Small delay to ensure Firestore updates propagate
            await Future.delayed(const Duration(milliseconds: 300));

            try {
              final achievementService = AchievementService();
              final currentUser = FirebaseAuth.instance.currentUser;

              // Use the updated progression state (totalSessions is incremented in awardSessionXP)
              final currentProgression = _ref.read(
                progressionControllerProvider,
              );
              final totalSessions = currentProgression.totalSessions;

              debugPrint(
                'Checking achievements - totalSessions: $totalSessions (previous: ${previousProgression.totalSessions})',
              );

              if (currentUser != null) {
                // Calculate actual user statistics
                final currentStreak =
                    await AchievementCalculator.calculateCurrentStreak(
                      currentUser.uid,
                    );
                final dailySessions =
                    await AchievementCalculator.calculateDailySessions(
                      currentUser.uid,
                    );
                final dailyHours =
                    await AchievementCalculator.calculateDailyHours(
                      currentUser.uid,
                    );
                final consecutiveDays =
                    await AchievementCalculator.calculateConsecutiveDays(
                      currentUser.uid,
                    );
                final consecutiveSessions =
                    await AchievementCalculator.calculateConsecutiveSessions(
                      currentUser.uid,
                    );
                final weeklySessions =
                    await AchievementCalculator.calculateWeeklySessions(
                      currentUser.uid,
                    );

                final newlyUnlocked = await achievementService
                    .checkAndUnlockAchievements(
                      totalSessions: totalSessions,
                      currentStreak: currentStreak,
                      dailySessions: dailySessions,
                      dailyHours: dailyHours,
                      isEarlySession: AchievementCalculator.isEarlySession(),
                      isLateSession: AchievementCalculator.isLateSession(),
                      consecutiveDays: consecutiveDays,
                      consecutiveSessions: consecutiveSessions,
                      weekendSession: AchievementCalculator.isWeekendSession(),
                      weeklySessions: weeklySessions,
                      breakCompliance: true, // Tracked when breaks complete
                      phoneFocus:
                          false, // Requires phone monitoring (not implemented)
                      dndEnabled:
                          state.focusShieldEnabled &&
                          _focusShieldActive, // Tracked via focus shield
                      tasksAdded: 0, // Tracked when tasks are added
                      customDurationUsed:
                          false, // Tracked when timer is customized
                      statsViewed: false, // Tracked when stats screen opens
                      dailyGoalReached: weeklyGoalCompleted,
                    );

                if (newlyUnlocked.isNotEmpty) {
                  debugPrint(
                    'Unlocked ${newlyUnlocked.length} achievements: ${newlyUnlocked.map((a) => a.name).join(", ")}',
                  );
                  state = state.copyWith(
                    achievementCelebrations: newlyUnlocked,
                  );
                  debugPrint(
                    'State updated with achievementCelebrations: ${state.achievementCelebrations?.length}',
                  );
                } else {
                  debugPrint('No new achievements unlocked');
                }
              }
            } catch (e) {
              debugPrint('Error checking achievements: $e');
            }

            // Update task stats if this is a task session
            await _taskSessionService.onSessionComplete(
              topicId: topic?.id,
              sessionDuration: pomodoroDuration,
              sessionType: 'focus',
            );
          } catch (e) {
            debugPrint('Failed to award XP: $e');
          }
        } else {
          // Save break sessions without XP or topic requirements
          try {
            final sessionType = currentType == PomodoroSessionType.shortBreak
                ? 'short_break'
                : 'long_break';

            await _saveSession(
              sessionStartAt: sessionStartAt,
              sessionEndAt: now,
              duration: pomodoroDuration,
              xpAwarded: 0, // No XP for breaks
              topicId: null, // No topic for breaks
              topicName: null, // No topic for breaks
              sessionType: sessionType,
            );
          } catch (e) {
            debugPrint('Failed to save break session: $e');
          }
        }
      } else {
        final topic = _ref.read(selectedTopicProvider);

        NotificationService.cancelSessionComplete();

        if (state.sessionNotificationsEnabled) {
          try {
            await NotificationService.showSessionComplete();
          } catch (e) {
            debugPrint('Failed to show session complete notification: $e');
          }
        }

        try {
          final progressionController = _ref.read(
            progressionControllerProvider.notifier,
          );
          final previousProgression = _ref.read(progressionControllerProvider);
          final celebration = await progressionController.awardSessionXP(
            sessionDuration,
          );

          if (celebration != null) {
            debugPrint(
              'Setting celebration in timer state (quick session): type=${celebration.type}, level=${celebration.newLevel}',
            );
            state = state.copyWith(celebration: celebration);
          } else {
            debugPrint(
              'No celebration returned from awardSessionXP (quick session)',
            );
          }

          // Save session to Firestore
          await _saveSession(
            sessionStartAt: sessionStartAt,
            sessionEndAt: now,
            duration: sessionDuration,
            xpAwarded: sessionDuration.inMinutes,
            topicId: topic?.id,
            topicName: topic?.name,
            sessionType: 'focus',
          );

          final weeklyGoalCompleted = await _checkAndTrackWeeklyGoal(user.uid);
          debugPrint(
            'Weekly goal completed check result (quick session): $weeklyGoalCompleted',
          );

          if (weeklyGoalCompleted) {
            debugPrint(
              'Setting weeklyGoalCompleted state to true (quick session)',
            );
            state = state.copyWith(weeklyGoalCompleted: true);
            debugPrint(
              'State updated (quick session) - weeklyGoalCompleted: ${state.weeklyGoalCompleted}',
            );
          }

          // Small delay to ensure Firestore updates propagate
          await Future.delayed(const Duration(milliseconds: 300));

          // Check and unlock achievements for quick session
          try {
            final achievementService = AchievementService();
            final currentUser = FirebaseAuth.instance.currentUser;

            if (currentUser != null) {
              // Get the updated progression state after awardSessionXP
              // totalSessions is incremented in awardSessionXP, so use previous + 1
              final totalSessions = previousProgression.totalSessions + 1;

              debugPrint(
                'Checking achievements (quick session) - totalSessions: $totalSessions (previous: ${previousProgression.totalSessions})',
              );

              // Calculate actual user statistics
              final currentStreak =
                  await AchievementCalculator.calculateCurrentStreak(
                    currentUser.uid,
                  );
              final dailySessions =
                  await AchievementCalculator.calculateDailySessions(
                    currentUser.uid,
                  );
              final dailyHours =
                  await AchievementCalculator.calculateDailyHours(
                    currentUser.uid,
                  );
              final consecutiveDays =
                  await AchievementCalculator.calculateConsecutiveDays(
                    currentUser.uid,
                  );
              final consecutiveSessions =
                  await AchievementCalculator.calculateConsecutiveSessions(
                    currentUser.uid,
                  );
              final weeklySessions =
                  await AchievementCalculator.calculateWeeklySessions(
                    currentUser.uid,
                  );

              final newlyUnlocked = await achievementService
                  .checkAndUnlockAchievements(
                    totalSessions: totalSessions,
                    currentStreak: currentStreak,
                    dailySessions: dailySessions,
                    dailyHours: dailyHours,
                    isEarlySession: AchievementCalculator.isEarlySession(),
                    isLateSession: AchievementCalculator.isLateSession(),
                    consecutiveDays: consecutiveDays,
                    consecutiveSessions: consecutiveSessions,
                    weekendSession: AchievementCalculator.isWeekendSession(),
                    weeklySessions: weeklySessions,
                    breakCompliance: true,
                    phoneFocus: false,
                    dndEnabled: state.focusShieldEnabled && _focusShieldActive,
                    tasksAdded: 0,
                    customDurationUsed: false,
                    statsViewed: false,
                    dailyGoalReached: weeklyGoalCompleted,
                  );

              if (newlyUnlocked.isNotEmpty) {
                debugPrint(
                  'Unlocked ${newlyUnlocked.length} achievements (quick session): ${newlyUnlocked.map((a) => a.name).join(", ")}',
                );
                state = state.copyWith(achievementCelebrations: newlyUnlocked);
                debugPrint(
                  'State updated with achievementCelebrations (quick session): ${state.achievementCelebrations?.length}',
                );
              } else {
                debugPrint('No new achievements unlocked (quick session)');
              }
            }
          } catch (e) {
            debugPrint('Error checking achievements (quick session): $e');
          }

          // Update task stats if this is a task session
          await _taskSessionService.onSessionComplete(
            topicId: topic?.id,
            sessionDuration: sessionDuration,
            sessionType: 'focus',
          );
        } catch (e) {
          debugPrint('Failed to award XP for quick session: $e');
        }
      }

      // Stop the timer but preserve the next session's duration if we're in Pomodoro mode
      // Otherwise reset to zero for quick sessions
      final shouldKeepNextSession =
          state.isPomodoroMode && state.pomodoroSession != null;
      state = state.copyWith(
        remaining: shouldKeepNextSession ? state.remaining : Duration.zero,
        isRunning: false,
        endAt: null,
      );
      _sessionStartAt = null;

      // Disable Focus Shield
      _disableFocusShield();
      // Note: Don't cancel notifications here - let them fire naturally

      // Auto-start next session if enabled and in Pomodoro mode
      if (state.autoStartEnabled &&
          state.isPomodoroMode &&
          state.pomodoroSession != null) {
        // Auto-starting next session
        // Add a small delay to allow UI to update
        Future.delayed(const Duration(milliseconds: 500), () {
          continueSession();
        });
      }
    } finally {
      _isCompleting = false;
    }
  }

  // Save session to Firestore
  Future<void> _saveSession({
    required DateTime sessionStartAt,
    required DateTime sessionEndAt,
    required Duration duration,
    required int xpAwarded,
    String? topicId,
    String? topicName,
    required String sessionType,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final session = SessionModel(
        id: '', // Will be set by Firestore
        userId: user.uid,
        startAt: sessionStartAt.toUtc(),
        endAt: sessionEndAt.toUtc(),
        duration: duration,
        xpAwarded: xpAwarded,
        createdAt: DateTime.now().toUtc(),
        topicId: topicId,
        topicName: topicName,
        sessionType: sessionType,
      );

      final sessionRepository = SessionRepository();
      await sessionRepository.saveSession(session);

      _ref.invalidate(weeklyStatsProvider);

      // Force refresh of progression data after a short delay to ensure Firestore update propagates
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _ref.invalidate(userProgressionStreamProvider(currentUser.uid));
        });
      }
    } catch (e) {
      debugPrint('Failed to save session to Firestore: $e');
    }
  }

  // Focus Shield methods
  Future<void> _loadFocusShieldSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final focusShieldEnabled = prefs.getBool('focus_shield_enabled') ?? false;
    final sessionNotificationsEnabled =
        prefs.getBool('session_notifications_enabled') ?? true;
    final breakNotificationsEnabled =
        prefs.getBool('break_notifications_enabled') ?? true;
    final autoStartEnabled = prefs.getBool('auto_start_enabled') ?? false;

    state = state.copyWith(
      focusShieldEnabled: focusShieldEnabled,
      sessionNotificationsEnabled: sessionNotificationsEnabled,
      breakNotificationsEnabled: breakNotificationsEnabled,
      autoStartEnabled: autoStartEnabled,
    );
  }

  Future<void> _saveFocusShieldSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('focus_shield_enabled', state.focusShieldEnabled);
    await prefs.setBool(
      'session_notifications_enabled',
      state.sessionNotificationsEnabled,
    );
    await prefs.setBool(
      'break_notifications_enabled',
      state.breakNotificationsEnabled,
    );
    await prefs.setBool('auto_start_enabled', state.autoStartEnabled);
  }

  Future<void> _enableFocusShield() async {
    if (!state.focusShieldEnabled) return;

    try {
      // First check if DND permission is granted
      final hasPermission = await FocusShieldChannel.hasDNDPermission();
      if (!hasPermission) {
        debugPrint('DND permission not granted - cannot enable Focus Shield');
        return;
      }

      // Only enable DND if permission is granted
      final success = await FocusShieldChannel.enableDND();
      if (success) {
        _focusShieldActive = true;
        debugPrint('Focus Shield enabled');

        await NotificationService.showFocusShieldOngoing(
          minutesRemaining: state.remaining.inMinutes,
        );

        // Track DND usage for achievements
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _trackingService.trackDNDUsage(
            uid: user.uid,
            date: DateTime.now(),
            usedDND: true,
          );
        }
      } else {
        debugPrint('Failed to enable Focus Shield - DND control failed');
      }
    } catch (e) {
      debugPrint('Error enabling Focus Shield: $e');
    }
  }

  Future<void> _disableFocusShield() async {
    if (!_focusShieldActive) return;

    try {
      final success = await FocusShieldChannel.disableDND();
      if (success) {
        _focusShieldActive = false;
        debugPrint('Focus Shield disabled');
        await NotificationService.cancelFocusShieldOngoing();
      } else {
        debugPrint('Failed to disable Focus Shield');
      }
    } catch (e) {
      debugPrint('Error disabling Focus Shield: $e');
    }
  }

  void _listenNotificationActions() {
    NotificationService.onNotificationAction.listen((response) async {
      switch (response.actionId) {
        case NotificationService.actionPause:
          pause();
          break;
        case NotificationService.actionStop:
          stop();
          break;
        case NotificationService.actionDisableShield:
          await _disableFocusShield();
          break;
        default:
          break;
      }
    });
  }

  Future<void> setFocusShieldEnabled(bool enabled) async {
    state = state.copyWith(focusShieldEnabled: enabled);
    await _saveFocusShieldSettings();

    // If enabling Focus Shield, check DND permission and provide feedback
    if (enabled) {
      final hasPermission = await FocusShieldChannel.hasDNDPermission();
      if (!hasPermission) {
        debugPrint('Focus Shield enabled but DND permission not granted');
      }
    }
  }

  Future<void> setSessionNotificationsEnabled(bool enabled) async {
    state = state.copyWith(sessionNotificationsEnabled: enabled);
    await _saveFocusShieldSettings();
  }

  Future<void> setBreakNotificationsEnabled(bool enabled) async {
    state = state.copyWith(breakNotificationsEnabled: enabled);
    await _saveFocusShieldSettings();
  }

  Future<void> setAutoStartEnabled(bool enabled) async {
    state = state.copyWith(autoStartEnabled: enabled);
    await _saveFocusShieldSettings();
  }

  bool get focusShieldEnabled => state.focusShieldEnabled;
  bool get sessionNotificationsEnabled => state.sessionNotificationsEnabled;
  bool get breakNotificationsEnabled => state.breakNotificationsEnabled;
  bool get focusShieldActive => _focusShieldActive;
  bool get autoStartEnabled => state.autoStartEnabled;

  Future<void> reloadSettings() async {
    await _loadFocusShieldSettings();
  }

  Future<bool> hasDNDPermission() async {
    return await FocusShieldChannel.hasDNDPermission();
  }

  Future<bool> openDNPSettings() async {
    try {
      final channelSuccess = await FocusShieldChannel.openDNPSettings();
      if (channelSuccess) return true;

      if (Platform.isAndroid) {
        const intent = AndroidIntent(
          action: 'android.settings.NOTIFICATION_POLICY_ACCESS_SETTINGS',
        );
        await intent.launch();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error opening DND settings: $e');
      return false;
    }
  }

  /// Returns true if weekly goal was just completed for the first time this week
  Future<bool> _checkAndTrackWeeklyGoal(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final weeklyGoal = userDoc.data()?['weeklyGoal'] as int? ?? 20;
      debugPrint('Checking weekly goal: target=$weeklyGoal');

      final progress = await _weeklyGoalService.getWeeklyGoalProgress(
        uid,
        weeklyGoal,
      );
      debugPrint(
        'Weekly goal progress: ${progress.currentSessions}/$weeklyGoal, isCompleted=${progress.isCompleted}',
      );

      if (progress.isCompleted) {
        final completions = await _trackingService.getWeeklyGoalCompletions(
          uid,
        );
        final weekKey = _getWeekKey(progress.weekStart);
        final wasAlreadyCompleted = completions[weekKey] == true;
        debugPrint(
          'Week key: $weekKey, wasAlreadyCompleted: $wasAlreadyCompleted',
        );

        await _trackingService.trackWeeklyGoalCompletion(
          uid: uid,
          weekStart: progress.weekStart,
          completed: true,
        );

        final shouldCelebrate = !wasAlreadyCompleted;
        debugPrint('Should celebrate weekly goal: $shouldCelebrate');
        return shouldCelebrate;
      }
      debugPrint('Weekly goal not completed yet');
      return false;
    } catch (e) {
      debugPrint('Error checking weekly goal: $e');
      return false;
    }
  }

  String _getWeekKey(DateTime weekStart) {
    final week = _getWeekNumber(weekStart);
    return '${weekStart.year}-W${week.toString().padLeft(2, '0')}';
  }

  int _getWeekNumber(DateTime date) {
    final year = date.year;
    final dayOfYear = date.difference(DateTime(year, 1, 1)).inDays + 1;
    final jan4 = DateTime(year, 1, 4);
    final jan4Weekday = jan4.weekday;
    final week1Start = jan4.subtract(Duration(days: jan4Weekday - 1));
    final week =
        ((dayOfYear - week1Start.difference(DateTime(year, 1, 1)).inDays) / 7)
            .ceil();
    return week;
  }
}

// Provider for the timer controller
final timerControllerProvider =
    StateNotifierProvider<TimerController, TimerState>((ref) {
      return TimerController(ref);
    });

final timerRemainingProvider = Provider<Duration>((ref) {
  return ref.watch(timerControllerProvider).remaining;
});

final timerRunningProvider = Provider<bool>((ref) {
  return ref.watch(timerControllerProvider).isRunning;
});
