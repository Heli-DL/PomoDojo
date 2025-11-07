import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'achievement_model.dart';
import 'achievement_tracking_service.dart';
import 'achievement_calculator.dart';
import '../../widgets/celebration_screen.dart';
import '../progression/progression_model.dart';
import '../progression/weekly_goal_service.dart';

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AchievementTrackingService _trackingService =
      AchievementTrackingService();
  final WeeklyGoalService _weeklyGoalService = WeeklyGoalService();

  Future<List<AchievementModel>> checkAndUnlockAchievements({
    required int totalSessions,
    required int currentStreak,
    int? dailySessions,
    double? dailyHours,
    bool? isEarlySession,
    bool? isLateSession,
    int? consecutiveDays,
    int? consecutiveSessions,
    int? completedTasks,
    bool? weekendSession,
    int? weeklySessions,
    bool? breakCompliance,
    bool? phoneFocus,
    bool? dndEnabled,
    int? tasksAdded,
    bool? customDurationUsed,
    bool? statsViewed,
    bool? dailyGoalReached,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return [];
      }

      final List<AchievementModel> newlyUnlocked = [];
      final now = DateTime.now();

      final userAchievements = await getUserAchievements(currentUser.uid);

      await _trackingService.getAllTrackingData(currentUser.uid);
      final weeklyGoalStreak = await _trackingService.getWeeklyGoalStreak(
        currentUser.uid,
      );
      final customDurationUsed = await _trackingService
          .hasCustomDurationBeenUsed(currentUser.uid);
      final statsViewCount = await _trackingService.getStatsViewCount(
        currentUser.uid,
      );

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final userData = userDoc.data() ?? {};
      final userXP = userData['xp'] as int? ?? 0;
      final userLevel = ProgressionModel.levelFromXP(userXP);
      final weeklyGoal = userData['weeklyGoal'] as int? ?? 20;

      final weeklyGoalProgress = await _weeklyGoalService.getWeeklyGoalProgress(
        currentUser.uid,
        weeklyGoal,
      );

      for (final achievement in Achievements.all) {
        if (userAchievements.any(
          (ua) => ua.id == achievement.id && ua.isUnlocked,
        )) {
          continue;
        }

        bool shouldUnlock = false;

        switch (achievement.type) {
          case AchievementType.sessions:
            // First Focus: Complete 1 session
            shouldUnlock = totalSessions >= achievement.requiredValue;
            // Sessions check
            break;

          case AchievementType.streak:
            // Streak achievements: Maintain streak for X days
            shouldUnlock = currentStreak >= achievement.requiredValue;
            // Streak check
            break;

          case AchievementType.totalPomodoros:
            // Total Pomodoros: Complete X total sessions
            shouldUnlock = totalSessions >= achievement.requiredValue;
            // Total Pomodoros check
            break;

          case AchievementType.dailySessions:
            // Daily sessions: Complete X sessions in one day
            // Special check for weekend_warrior - must be weekend AND >= 5 sessions
            if (achievement.id == 'weekend_warrior') {
              final isWeekend = DateTime.now().weekday >= 6;
              final dailyCount = dailySessions ?? 0;
              shouldUnlock =
                  isWeekend && dailyCount >= achievement.requiredValue;
            } else {
              shouldUnlock = (dailySessions ?? 0) >= achievement.requiredValue;
            }
            // Daily Sessions check
            break;

          case AchievementType.dailyHours:
            // Daily hours: Focus for X hours in one day
            shouldUnlock = (dailyHours ?? 0) >= achievement.requiredValue;
            // Daily Hours check
            break;

          case AchievementType.earlySession:
            // Early session: Complete session before 8 AM
            shouldUnlock = isEarlySession == true;
            // Early Session check
            break;

          case AchievementType.lateSession:
            // Late session: Complete session after 11 PM
            shouldUnlock = isLateSession == true;
            // Late Session check
            break;

          case AchievementType.consecutiveDays:
            // Consecutive days: Do at least 1 Pomodoro for X consecutive days
            shouldUnlock = (consecutiveDays ?? 0) >= achievement.requiredValue;
            // Consecutive Days check
            break;

          case AchievementType.consecutiveSessions:
            // Consecutive sessions: Complete X sessions without pause
            shouldUnlock =
                (consecutiveSessions ?? 0) >= achievement.requiredValue;
            // Consecutive Sessions check
            break;

          case AchievementType.completedTasks:
            // Completed tasks: Complete X different tasks (lifetime)
            final completedTasksCount = await _trackingService
                .getCompletedTasksCount(currentUser.uid);
            shouldUnlock = completedTasksCount >= achievement.requiredValue;
            // Completed Tasks check
            break;

          case AchievementType.weekendSessions:
            // Weekend sessions: Focus on both Saturday and Sunday
            shouldUnlock = weekendSession == true;
            // Weekend Sessions check
            break;

          case AchievementType.weeklySessions:
            // Weekly sessions: Do at least X Pomodoros every day for a week
            // For daily_discipline, need 3 sessions per day for 7 consecutive days
            if (achievement.id == 'daily_discipline') {
              final consecutiveDays =
                  await AchievementCalculator.calculateConsecutiveDaysWithMinSessions(
                    currentUser.uid,
                    3, // Minimum 3 sessions per day
                  );
              shouldUnlock = consecutiveDays >= achievement.requiredValue;
            } else {
              // For other weekly session achievements, use total weekly sessions
              shouldUnlock = (weeklySessions ?? 0) >= achievement.requiredValue;
            }
            // Weekly Sessions check
            break;

          case AchievementType.breakCompliance:
            // Break compliance: Take all scheduled breaks for X days
            final breakStreak = await _trackingService.getBreakComplianceStreak(
              currentUser.uid,
              achievement.requiredValue,
            );
            shouldUnlock = breakStreak >= achievement.requiredValue;
            // Break Compliance check
            break;

          case AchievementType.phoneFocus:
            // Phone focus: Stay focused for X+ hours without touching phone
            // Note: This requires phone usage monitoring which isn't implemented
            // For now, mark as not available - would need phone state listener
            shouldUnlock = false; // Requires phone monitoring feature
            // Phone Focus check
            break;

          case AchievementType.dndCompliance:
            // DND compliance: Enable DND mode every session for X days
            final dndStreak = await _trackingService.getDNDComplianceStreak(
              currentUser.uid,
              achievement.requiredValue,
            );
            shouldUnlock = dndStreak >= achievement.requiredValue;
            // DND Compliance check
            break;

          case AchievementType.taskPlanning:
            // Task planning: Add X tasks before starting day
            final todayTasks = await _trackingService.getTasksAddedOnDate(
              currentUser.uid,
              DateTime.now(),
            );
            shouldUnlock = todayTasks >= achievement.requiredValue;
            // Task Planning check
            break;

          case AchievementType.customDuration:
            // Custom duration: Customize Pomodoro durations for the first time
            shouldUnlock = customDurationUsed;
            // Custom Duration check
            break;

          case AchievementType.statsViewing:
            // Stats viewing: View weekly stats X times
            shouldUnlock = statsViewCount >= achievement.requiredValue;
            // Stats Viewing check
            break;

          case AchievementType.dailyGoal:
            // Daily goal achievements: Weekly goal completion and streaks
            // Check different achievement requirements
            if (achievement.requiredValue == 1) {
              // First time completion, overachiever, double down, triple threat, comeback champion
              if (achievement.id == 'weekly_starter') {
                // Unlock if weekly goal was just reached for the first time
                // Check if this is the first completion by checking if streak is exactly 1
                // If dailyGoalReached is true, it means the goal was just completed this session
                // If streak is 1, it means only the current week is completed (first time)
                if (dailyGoalReached == true) {
                  // Get completions to check if current week is the only completed week
                  final completions = await _trackingService
                      .getWeeklyGoalCompletions(currentUser.uid);
                  final currentWeekStart = _weeklyGoalService
                      .getCurrentWeekStart();
                  final weekKey = _getWeekKeyForDate(currentWeekStart);

                  // Check if current week is completed and it's the only completed week
                  final isCurrentWeekCompleted = completions[weekKey] == true;
                  final totalCompletedWeeks = completions.values
                      .where((v) => v == true)
                      .length;

                  // Unlock if current week is completed and it's the first (and only) completed week
                  shouldUnlock =
                      isCurrentWeekCompleted && totalCompletedWeeks == 1;
                  debugPrint(
                    'Weekly Starter check: dailyGoalReached=true, weekKey=$weekKey, isCurrentWeekCompleted=$isCurrentWeekCompleted, totalCompletedWeeks=$totalCompletedWeeks, shouldUnlock=$shouldUnlock',
                  );
                } else {
                  shouldUnlock = false;
                }
              } else if (achievement.id == 'overachiever_weekly') {
                // Exceed goal by 50%+ (only unlock when goal is completed)
                shouldUnlock =
                    dailyGoalReached == true &&
                    weeklyGoalProgress.currentSessions >=
                        (weeklyGoalProgress.weeklyGoal * 1.5);
              } else if (achievement.id == 'double_down_weekly') {
                // Double the goal (only unlock when goal is completed)
                shouldUnlock =
                    dailyGoalReached == true &&
                    weeklyGoalProgress.currentSessions >=
                        (weeklyGoalProgress.weeklyGoal * 2);
              } else if (achievement.id == 'triple_threat_weekly') {
                // Triple the goal (only unlock when goal is completed)
                shouldUnlock =
                    dailyGoalReached == true &&
                    weeklyGoalProgress.currentSessions >=
                        (weeklyGoalProgress.weeklyGoal * 3);
              } else if (achievement.id == 'comeback_champion_weekly') {
                // Completed after breaking streak - check if there was a gap in weekly completions
                if (dailyGoalReached == true &&
                    weeklyGoalProgress.isCompleted) {
                  final completions = await _trackingService
                      .getWeeklyGoalCompletions(currentUser.uid);
                  final currentWeekStart = _weeklyGoalService
                      .getCurrentWeekStart();
                  final currentWeekKey = _getWeekKeyForDate(currentWeekStart);

                  // Check if there was a previous streak that was broken
                  // This means: there are completed weeks before, but there's a gap before the current week
                  final hasBrokenStreak = _hasWeeklyGoalStreakBeenBroken(
                    completions,
                    currentWeekKey,
                    currentWeekStart,
                  );

                  shouldUnlock = hasBrokenStreak;
                  debugPrint(
                    'Comeback Champion check: dailyGoalReached=true, currentWeekKey=$currentWeekKey, hasBrokenStreak=$hasBrokenStreak, shouldUnlock=$shouldUnlock',
                  );
                } else {
                  shouldUnlock = false;
                }
              } else {
                shouldUnlock = weeklyGoalStreak >= 1;
              }
            } else {
              // Streak-based achievements
              shouldUnlock = weeklyGoalStreak >= achievement.requiredValue;
            }
            // Daily Goal check
            break;

          case AchievementType.level:
            // Level: Reach a specific level
            shouldUnlock = userLevel >= achievement.requiredValue;
            // Level check
            break;
        }

        if (shouldUnlock) {
          // Unlock the achievement
          final unlockedAchievement = achievement.copyWith(unlockedAt: now);
          await _unlockAchievement(currentUser.uid, unlockedAchievement);
          newlyUnlocked.add(unlockedAchievement);

          // Achievement unlocked
        } else {
          // Not enough progress to unlock
        }
      }

      return newlyUnlocked;
    } catch (e) {
      debugPrint('Error checking achievements: $e');
      return [];
    }
  }

  // Get all user achievements
  Future<List<AchievementModel>> getUserAchievements(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('achievements')
          .get();

      final List<AchievementModel> achievements = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final baseAchievement = Achievements.getById(doc.id);

        if (baseAchievement != null) {
          final unlockedAt = data['unlockedAt'] != null
              ? DateTime.parse(data['unlockedAt'] as String)
              : null;

          achievements.add(baseAchievement.copyWith(unlockedAt: unlockedAt));
        }
      }

      // Add any missing achievements (not yet unlocked)
      for (final achievement in Achievements.all) {
        if (!achievements.any((a) => a.id == achievement.id)) {
          achievements.add(achievement);
        }
      }

      return achievements;
    } catch (e) {
      debugPrint('Error getting user achievements: $e');
      return Achievements.all;
    }
  }

  // Stream user achievements for real-time updates
  Stream<List<AchievementModel>> streamUserAchievements(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('achievements')
        .snapshots()
        .map((snapshot) {
          final List<AchievementModel> achievements = [];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final baseAchievement = Achievements.getById(doc.id);

            if (baseAchievement != null) {
              final unlockedAt = data['unlockedAt'] != null
                  ? DateTime.parse(data['unlockedAt'] as String)
                  : null;

              achievements.add(
                baseAchievement.copyWith(unlockedAt: unlockedAt),
              );
            }
          }

          // Add any missing achievements (not yet unlocked)
          for (final achievement in Achievements.all) {
            if (!achievements.any((a) => a.id == achievement.id)) {
              achievements.add(achievement);
            }
          }

          return achievements;
        });
  }

  // Unlock a specific achievement (public method)
  Future<void> unlockAchievement(
    String uid,
    AchievementModel achievement,
  ) async {
    if (achievement.unlockedAt == null) {
      throw ArgumentError('Achievement must have unlockedAt set');
    }
    await _unlockAchievement(uid, achievement);
  }

  // Unlock a specific achievement (private method)
  Future<void> _unlockAchievement(
    String uid,
    AchievementModel achievement,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('achievements')
          .doc(achievement.id)
          .set({
            'unlockedAt': achievement.unlockedAt!.toIso8601String(),
            'unlockedAtTimestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
      rethrow;
    }
  }

  // Get achievement progress for a specific achievement
  Future<AchievementProgress> getAchievementProgress(
    String uid,
    AchievementModel achievement,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return AchievementProgress(0, achievement.requiredValue);
      }

      // Get current user stats
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        return AchievementProgress(0, achievement.requiredValue);
      }

      final userData = userDoc.data()!;
      final totalSessions = userData['totalSessions'] as int? ?? 0;
      final currentStreak = userData['streak'] as int? ?? 0;

      int currentValue = 0;

      switch (achievement.type) {
        case AchievementType.sessions:
        case AchievementType.totalPomodoros:
          currentValue = totalSessions;
          break;
        case AchievementType.streak:
          currentValue = currentStreak;
          break;
        case AchievementType.dailySessions:
          // Special check for weekend_warrior - must be weekend AND >= 5 sessions
          if (achievement.id == 'weekend_warrior') {
            final isWeekend = DateTime.now().weekday >= 6;
            final dailyCount =
                await AchievementCalculator.calculateDailySessions(uid);
            currentValue = (isWeekend && dailyCount >= 5) ? 1 : 0;
          } else {
            currentValue = await AchievementCalculator.calculateDailySessions(
              uid,
            );
          }
          break;
        case AchievementType.dailyHours:
          currentValue = (await AchievementCalculator.calculateDailyHours(
            uid,
          )).toInt();
          break;
        case AchievementType.earlySession:
          currentValue = AchievementCalculator.isEarlySession() ? 1 : 0;
          break;
        case AchievementType.lateSession:
          currentValue = AchievementCalculator.isLateSession() ? 1 : 0;
          break;
        case AchievementType.consecutiveDays:
          currentValue = await AchievementCalculator.calculateConsecutiveDays(
            uid,
          );
          break;
        case AchievementType.consecutiveSessions:
          currentValue =
              await AchievementCalculator.calculateConsecutiveSessions(uid);
          break;
        case AchievementType.completedTasks:
          currentValue = await _trackingService.getCompletedTasksCount(uid);
          break;
        case AchievementType.weekendSessions:
        case AchievementType.weeklySessions:
        case AchievementType.breakCompliance:
        case AchievementType.phoneFocus:
        case AchievementType.dndCompliance:
        case AchievementType.taskPlanning:
        case AchievementType.customDuration:
        case AchievementType.statsViewing:
        case AchievementType.dailyGoal:
          // Get weekly goal streak for progress display
          currentValue = await _trackingService.getWeeklyGoalStreak(uid);
          break;
        case AchievementType.level:
          // These require more complex tracking that isn't available in basic user data
          currentValue = 0;
          break;
      }

      return AchievementProgress(currentValue, achievement.requiredValue);
    } catch (e) {
      debugPrint('Error getting achievement progress: $e');
      return AchievementProgress(0, achievement.requiredValue);
    }
  }

  // Show celebration for newly unlocked achievements
  static void showAchievementCelebrations(
    BuildContext context,
    List<AchievementModel> newlyUnlocked, {
    VoidCallback? onAllShown,
  }) {
    if (newlyUnlocked.isEmpty) {
      debugPrint('showAchievementCelebrations: No achievements to show');
      return;
    }

    if (!context.mounted) {
      debugPrint('showAchievementCelebrations: Context not mounted');
      return;
    }

    debugPrint(
      'showAchievementCelebrations called with ${newlyUnlocked.length} achievements: ${newlyUnlocked.map((a) => a.name).join(", ")}',
    );

    try {
      // Show celebrations for all achievements in sequence
      _showAchievementSequence(
        context,
        newlyUnlocked,
        0,
        onAllShown: onAllShown,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in showAchievementCelebrations: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // Show achievements one by one in sequence
  static void _showAchievementSequence(
    BuildContext context,
    List<AchievementModel> achievements,
    int currentIndex, {
    VoidCallback? onAllShown,
  }) {
    if (currentIndex >= achievements.length) return;
    if (!context.mounted) {
      debugPrint('Context not mounted, skipping achievement display');
      return;
    }

    final achievement = achievements[currentIndex];

    // Validate achievement data
    if (achievement.name.isEmpty || achievement.description.isEmpty) {
      debugPrint('Invalid achievement data at index $currentIndex, skipping');
      if (currentIndex < achievements.length - 1) {
        _showAchievementSequence(context, achievements, currentIndex + 1);
      }
      return;
    }

    final isLast = currentIndex == achievements.length - 1;
    final title = achievements.length > 1
        ? 'Achievement Unlocked! (${currentIndex + 1}/${achievements.length})'
        : 'Achievement Unlocked!';

    debugPrint(
      'Showing achievement dialog: ${achievement.name} (${currentIndex + 1}/${achievements.length})',
    );

    try {
      CelebrationHelper.showAchievement(
        context,
        title: title,
        subtitle: achievement.name,
        description: achievement.description,
        icon: achievement.icon,
        color: achievement.color,
        buttonText: isLast ? 'Close' : 'Continue',
        onContinue: () {
          if (!context.mounted) {
            debugPrint('Context not mounted in onContinue callback');
            return;
          }

          debugPrint(
            '${isLast ? 'Close' : 'Continue'} button pressed for achievement ${currentIndex + 1}/${achievements.length}',
          );

          try {
            final navigator = Navigator.of(context, rootNavigator: true);
            if (navigator.canPop()) {
              navigator.pop();
              debugPrint('Dialog closed successfully');
            } else {
              debugPrint('Cannot pop dialog - no dialogs in stack');
            }

            // Show next achievement after a short delay if not last
            if (!isLast) {
              debugPrint('Showing next achievement in sequence');
              Future.delayed(const Duration(milliseconds: 500), () {
                if (context.mounted) {
                  _showAchievementSequence(
                    context,
                    achievements,
                    currentIndex + 1,
                    onAllShown: onAllShown,
                  );
                } else {
                  debugPrint('Context not mounted, skipping next achievement');
                  // Call onAllShown if context is lost
                  onAllShown?.call();
                }
              });
            } else {
              // All achievements shown - call callback
              debugPrint('All achievements shown');
              onAllShown?.call();
            }
          } catch (e) {
            debugPrint('Error handling onContinue: $e');
            // Call onAllShown on error
            onAllShown?.call();
          }
        },
        onClose: () {
          if (!context.mounted) {
            debugPrint('Context not mounted in onClose callback');
            return;
          }

          debugPrint('X button pressed - closing achievement dialog');

          try {
            final navigator = Navigator.of(context, rootNavigator: true);
            if (navigator.canPop()) {
              navigator.pop();
              debugPrint('Dialog closed successfully');
            } else {
              debugPrint('Cannot pop dialog - no dialogs in stack');
            }
            // Call onAllShown when user closes dialog
            onAllShown?.call();
          } catch (e) {
            debugPrint('Error handling onClose: $e');
            // Call onAllShown on error
            onAllShown?.call();
          }
        },
      );
    } catch (e) {
      debugPrint('Error showing achievement dialog: $e');
    }
  }

  // Reset all user achievements (for testing/debugging)
  static Future<void> resetUserAchievements(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final achievementsRef = firestore
          .collection('users')
          .doc(uid)
          .collection('achievements');

      final snapshot = await achievementsRef.get();

      // If there are no achievements, nothing to delete
      if (snapshot.docs.isEmpty) {
        debugPrint('No achievements to reset for user: $uid');
        return;
      }

      // Firestore batch writes have a limit of 500 operations
      // Split into batches if needed
      const batchLimit = 500;
      final docs = snapshot.docs;

      for (int i = 0; i < docs.length; i += batchLimit) {
        final batch = firestore.batch();
        final end = (i + batchLimit < docs.length)
            ? i + batchLimit
            : docs.length;

        for (int j = i; j < end; j++) {
          batch.delete(docs[j].reference);
        }

        await batch.commit();
        debugPrint('Deleted batch of ${end - i} achievements for user: $uid');
      }

      debugPrint(
        'All achievements reset for user: $uid (total: ${docs.length})',
      );
    } catch (e, stackTrace) {
      debugPrint('Error resetting achievements: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't rethrow - let the caller handle error display
      throw Exception('Failed to reset achievements: $e');
    }
  }

  // Get all achievement progress for a user
  Future<Map<String, AchievementProgress>> getAllAchievementProgress(
    String uid,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return {};

      // Get unlocked achievements first to check unlock status
      final userAchievements = await getUserAchievements(uid);
      final unlockedAchievementIds = userAchievements
          .where((a) => a.isUnlocked)
          .map((a) => a.id)
          .toSet();

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) return {};

      final userData = userDoc.data()!;
      final currentStreak = userData['streak'] as int? ?? 0;

      // Count actual focus sessions from Firestore for accurate progress
      final actualFocusSessions = await _countFocusSessions(currentUser.uid);

      final Map<String, AchievementProgress> progress = {};

      for (final achievement in Achievements.all) {
        // If achievement is unlocked, always show 100% progress
        if (unlockedAchievementIds.contains(achievement.id)) {
          progress[achievement.id] = AchievementProgress(
            achievement.requiredValue,
            achievement.requiredValue,
          );
          continue;
        }

        int currentValue = 0;

        switch (achievement.type) {
          case AchievementType.sessions:
          case AchievementType.totalPomodoros:
            currentValue = actualFocusSessions;
            break;
          case AchievementType.streak:
            currentValue = currentStreak;
            break;
          case AchievementType.dailySessions:
            // Special check for weekend_warrior - must be weekend AND >= 5 sessions
            if (achievement.id == 'weekend_warrior') {
              final isWeekend = DateTime.now().weekday >= 6;
              final dailyCount =
                  await AchievementCalculator.calculateDailySessions(uid);
              currentValue = (isWeekend && dailyCount >= 5) ? 1 : 0;
            } else {
              currentValue = await AchievementCalculator.calculateDailySessions(
                uid,
              );
            }
            break;
          case AchievementType.dailyHours:
            currentValue = (await AchievementCalculator.calculateDailyHours(
              uid,
            )).toInt();
            break;
          case AchievementType.earlySession:
            currentValue = AchievementCalculator.isEarlySession() ? 1 : 0;
            break;
          case AchievementType.lateSession:
            currentValue = AchievementCalculator.isLateSession() ? 1 : 0;
            break;
          case AchievementType.consecutiveDays:
            currentValue = await AchievementCalculator.calculateConsecutiveDays(
              uid,
            );
            break;
          case AchievementType.consecutiveSessions:
            currentValue =
                await AchievementCalculator.calculateConsecutiveSessions(uid);
            break;
          case AchievementType.completedTasks:
            currentValue = await _trackingService.getCompletedTasksCount(uid);
            break;
          case AchievementType.weekendSessions:
          case AchievementType.weeklySessions:
            // For daily_discipline, calculate consecutive days with 3+ sessions
            if (achievement.id == 'daily_discipline') {
              currentValue =
                  await AchievementCalculator.calculateConsecutiveDaysWithMinSessions(
                    uid,
                    3,
                  );
            } else {
              // For other weekly session achievements, use total weekly sessions
              currentValue =
                  await AchievementCalculator.calculateWeeklySessions(uid);
            }
            break;
          case AchievementType.breakCompliance:
          case AchievementType.phoneFocus:
          case AchievementType.dndCompliance:
          case AchievementType.taskPlanning:
          case AchievementType.customDuration:
          case AchievementType.statsViewing:
          case AchievementType.dailyGoal:
            // Special handling for getting_started achievement
            if (achievement.id == 'getting_started') {
              // Check if onboarding is completed
              final onboardingCompleted =
                  userData['onboardingCompleted'] as bool? ?? false;
              currentValue = onboardingCompleted ? 1 : 0;
            } else {
              // Get weekly goal streak for progress display
              currentValue = await _trackingService.getWeeklyGoalStreak(uid);
            }
            break;
          case AchievementType.level:
            // These require more complex tracking that isn't available in basic user data
            currentValue = 0;
            break;
        }

        progress[achievement.id] = AchievementProgress(
          currentValue,
          achievement.requiredValue,
        );
      }

      return progress;
    } catch (e) {
      debugPrint('Error getting all achievement progress: $e');
      return {};
    }
  }

  // Count actual focus sessions from Firestore
  Future<int> _countFocusSessions(String uid) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .where('sessionType', isEqualTo: 'focus')
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('Error counting focus sessions: $e');
      // Fallback to user document totalSessions if query fails
      try {
        final userDoc = await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          return userData['totalSessions'] as int? ?? 0;
        }
      } catch (e2) {
        debugPrint('Error getting fallback totalSessions: $e2');
      }
      return 0;
    }
  }

  /// Get week key (YYYY-WW) for a given date
  String _getWeekKeyForDate(DateTime weekStart) {
    // Calculate week number (ISO week)
    final dayOfYear =
        weekStart.difference(DateTime(weekStart.year, 1, 1)).inDays + 1;
    final weekNumber = ((dayOfYear - weekStart.weekday + 10) / 7).floor();
    return '${weekStart.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// Check if weekly goal streak was broken before the current week
  /// Returns true if there are completed weeks in history, but the week before current was not completed
  bool _hasWeeklyGoalStreakBeenBroken(
    Map<String, bool> completions,
    String currentWeekKey,
    DateTime currentWeekStart,
  ) {
    if (completions.isEmpty) return false;

    // Get the previous week (one week before current)
    final previousWeekStart = currentWeekStart.subtract(
      const Duration(days: 7),
    );
    final previousWeekKey = _getWeekKeyForDate(previousWeekStart);

    // Check if previous week was completed
    final previousWeekCompleted = completions[previousWeekKey] == true;

    // Check if there are any completed weeks before the previous week
    // (meaning there was a streak that was broken)
    final sortedWeeks = completions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    // Find weeks that are older than the previous week
    final weeksBeforePrevious = sortedWeeks.where((weekKey) {
      // Compare week keys (they're in format YYYY-WW)
      return weekKey.compareTo(previousWeekKey) < 0;
    }).toList();

    // Check if any of those older weeks were completed
    final hasCompletedWeeksBefore = weeksBeforePrevious.any(
      (weekKey) => completions[weekKey] == true,
    );

    // Streak was broken if:
    // 1. There are completed weeks in the past
    // 2. The previous week (immediately before current) was NOT completed
    // This means there was a gap, indicating a broken streak
    final streakWasBroken = hasCompletedWeeksBefore && !previousWeekCompleted;

    debugPrint(
      'Comeback Champion streak check: currentWeekKey=$currentWeekKey, previousWeekKey=$previousWeekKey, previousWeekCompleted=$previousWeekCompleted, hasCompletedWeeksBefore=$hasCompletedWeeksBefore, streakWasBroken=$streakWasBroken',
    );

    return streakWasBroken;
  }
}

class AchievementProgress {
  final int current;
  final int required;

  const AchievementProgress(this.current, this.required);

  double get percentage =>
      required > 0 ? (current / required).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => current >= required;
  int get remaining => (required - current).clamp(0, required);
}
