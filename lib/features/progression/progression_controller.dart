import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'progression_model.dart';
import 'martial_rank.dart';
import '../auth/user_repository.dart';
import '../achievements/achievement_service.dart';
import 'weekly_goal_service.dart';
import 'progression_celebration_service.dart';

class ProgressionController extends Notifier<ProgressionModel> {
  @override
  ProgressionModel build() {
    final progression = const ProgressionModel(
      level: 1,
      xp: 0,
      totalSessions: 0,
      rank: MartialRank.novice,
    );
    _loadProgression();
    return progression;
  }

  final UserRepository _userRepository = UserRepository();

  // Load progression from user data
  Future<void> _loadProgression() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userModel = await _userRepository.getUser(currentUser.uid);
      if (userModel == null) return;

      // Use all-time stats directly from user document
      final progression = ProgressionModel.fromStats(
        userModel.xp,
        userModel.totalSessions,
      );
      state = progression;
    } catch (e) {
      debugPrint('Error loading progression: $e');
    }
  }

  // Award XP for completed focus session: 1 XP per focus minute
  Future<ProgressionCelebration?> awardSessionXP(
    Duration sessionDuration,
  ) async {
    try {
      final int totalXP = sessionDuration.inMinutes;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;

      // Get current user data from Firestore to ensure we have the latest XP
      final userModel = await _userRepository.getUser(currentUser.uid);
      if (userModel == null) return null;

      // Use actual current XP from Firestore, not potentially stale state
      final currentXP = userModel.xp;
      final currentSessions = userModel.totalSessions;
      final previousProgression = ProgressionModel.fromStats(
        currentXP,
        currentSessions,
      );

      // Create new progression state
      final newXP = currentXP + totalXP;
      final newSessions = currentSessions + 1;
      final newProgression = ProgressionModel.fromStats(newXP, newSessions);

      // Update local state
      state = newProgression;

      // Update user stats in Firestore
      await _userRepository.updateUserStats(
        currentUser.uid,
        xpToAdd: totalXP,
        totalSessions: newSessions,
      );

      // Session XP awarded
      debugPrint(
        'Progression: Previous - Level ${previousProgression.level}, XP ${previousProgression.xp}, Rank ${previousProgression.rank.name}',
      );
      debugPrint(
        'Progression: New - Level ${newProgression.level}, XP ${newProgression.xp}, Rank ${newProgression.rank.name}',
      );

      // Check for level up - use level comparison (handles exact boundaries correctly)
      final levelUp = newProgression.level > previousProgression.level;
      debugPrint('Level up check: $levelUp (${newProgression.level} > ${previousProgression.level})');

      // Check for rank upgrade (rank up levels: 3, 5, 7, 9, 11)
      final rankUp = newProgression.isRankUpgrade(previousProgression);
      debugPrint('Rank up check: $rankUp (${newProgression.rank.name} vs ${previousProgression.rank.name})');
      final rankUpLevels = [3, 5, 7, 9, 11];

      // Unlock background on level up (but not on rank up levels)
      int? unlockedBackgroundNumber;
      if (levelUp && !rankUpLevels.contains(newProgression.level)) {
        // Calculate background number by counting rank-up levels below current level
        // Rank-up levels: 3, 5, 7, 9, 11
        int rankUpsBelow = rankUpLevels
            .where((rankLevel) => rankLevel < newProgression.level)
            .length;
        int backgroundNumber = newProgression.level - rankUpsBelow;

        // Cap at 20 backgrounds
        backgroundNumber = backgroundNumber.clamp(1, 20);

        try {
          await _userRepository.unlockBackground(
            currentUser.uid,
            backgroundNumber,
          );
          unlockedBackgroundNumber = backgroundNumber;
          // Unlocked background at level up
        } catch (e) {
          debugPrint('Error unlocking background: $e');
        }
      }

      if (rankUp) {
        // Rank up (always happens with level up, so include XP for level up screen)
        debugPrint(
          'Creating rank up celebration: Level ${newProgression.level}, Rank ${newProgression.rank.name}',
        );
        return ProgressionCelebration.rankUp(
          newRank: newProgression.rank,
          newLevel: newProgression.level,
          newXp: newProgression.xp,
        );
      } else if (levelUp) {
        // Level up
        debugPrint(
          'Creating level up celebration: Level ${newProgression.level}, XP ${newProgression.xp}, Background: $unlockedBackgroundNumber',
        );
        return ProgressionCelebration.levelUp(
          newLevel: newProgression.level,
          newXp: newProgression.xp,
          unlockedBackground: unlockedBackgroundNumber,
        );
      }

      debugPrint('No celebration - levelUp: $levelUp, rankUp: $rankUp');
      return null;
    } catch (e) {
      debugPrint('Error awarding session XP: $e');
      return null;
    }
  }

  // Bonus calculation removed: now strictly 1 XP per minute

  // Force refresh progression
  Future<void> refreshProgression() async {
    await _loadProgression();
  }

  // Reset state for new user
  void resetForNewUser() {
    state = const ProgressionModel(
      level: 1,
      xp: 0,
      totalSessions: 0,
      rank: MartialRank.novice,
    );
    _loadProgression();
  }

  // Manual achievement check (for debugging)
  Future<void> checkAchievementsManually() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userModel = await _userRepository.getUser(currentUser.uid);
      if (userModel == null) return;

      // Manual achievement check

      final achievementService = AchievementService();
      await achievementService.checkAndUnlockAchievements(
        totalSessions: userModel.totalSessions,
        currentStreak: userModel.streak,
      );

      // No verbose logs for manual check results
    } catch (e) {
      debugPrint('Error in manual achievement check: $e');
    }
  }

  // (Migration helper removed)

  // Get formatted XP display
  String get formattedXP => '${state.xp} XP';

  // Get formatted level display
  String get formattedLevel => 'Level ${state.level}';

  // Get formatted rank display
  String get formattedRank => '${state.rank.icon} ${state.rank.name}';

  // Get progress text
  String get progressText {
    if (state.level >= 20) {
      // Cap display at reasonable level
      return '${state.xp} XP • Max Level Reached';
    }
    return '${state.xpProgress}/${state.xpNeeded} XP to Level ${state.level + 1}';
  }

  // Get motivational message based on progress
  String get motivationalMessage {
    final percentage = state.progressPercentage;

    if (percentage >= 0.9) {
      return 'Almost there! One more session to level up! 🔥';
    } else if (percentage >= 0.7) {
      return 'Great progress! Keep the momentum going! 💪';
    } else if (percentage >= 0.5) {
      return 'Halfway to your next level! Stay focused! 🎯';
    } else if (percentage >= 0.3) {
      return 'Building strength through discipline! 🥋';
    } else {
      return state.rank.dialogue;
    }
  }
}

// Provider for progression controller
final progressionControllerProvider =
    NotifierProvider<ProgressionController, ProgressionModel>(() {
      return ProgressionController();
    });

// User-specific progression provider (simplified - using stream provider instead)
// final userProgressionProvider = NotifierProvider.family<ProgressionController, ProgressionModel, String?>((ref, userId) {
//   final controller = ProgressionController();
//   ref.onDispose(() {
//     debugPrint('🗑️ Disposing progression controller for user: $userId');
//   });
//   return controller;
// });

// Stream-based user progression provider that reacts to Firebase changes
final userProgressionStreamProvider =
    StreamProvider.family<ProgressionModel, String>((ref, uid) {
      final userRepository = UserRepository();
      return userRepository.streamUser(uid).map((userModel) {
        if (userModel == null) {
          return const ProgressionModel(
            level: 1,
            xp: 0,
            totalSessions: 0,
            rank: MartialRank.novice,
          );
        }

        return ProgressionModel.fromStats(
          userModel.xp,
          userModel.totalSessions,
        );
      });
    });

// Weekly Goal Progress Provider
final weeklyGoalProgressProvider =
    StreamProvider.family<WeeklyGoalProgress, ({String uid, int weeklyGoal})>((
      ref,
      params,
    ) {
      final weeklyGoalService = WeeklyGoalService();
      return weeklyGoalService.streamWeeklyGoalProgress(
        params.uid,
        params.weeklyGoal,
      );
    });
