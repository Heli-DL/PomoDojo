import 'package:flutter/material.dart';
import '../../widgets/celebration_screen.dart';
import 'martial_rank.dart';

class ProgressionCelebration {
  final ProgressionCelebrationType type;
  final int newLevel;
  final int newXp;
  final MartialRank? newRank;
  final int? unlockedBackground;

  const ProgressionCelebration._({
    required this.type,
    required this.newLevel,
    required this.newXp,
    this.newRank,
    this.unlockedBackground,
  });

  factory ProgressionCelebration.levelUp({
    required int newLevel,
    required int newXp,
    int? unlockedBackground,
  }) {
    return ProgressionCelebration._(
      type: ProgressionCelebrationType.levelUp,
      newLevel: newLevel,
      newXp: newXp,
      unlockedBackground: unlockedBackground,
    );
  }

  factory ProgressionCelebration.rankUp({
    required MartialRank newRank,
    required int newLevel,
    int newXp = 0, // XP for showing level up screen first
  }) {
    return ProgressionCelebration._(
      type: ProgressionCelebrationType.rankUp,
      newLevel: newLevel,
      newXp: newXp,
      newRank: newRank,
    );
  }

  factory ProgressionCelebration.backgroundUnlock({
    required int newLevel,
    required int unlockedBackground,
  }) {
    return ProgressionCelebration._(
      type: ProgressionCelebrationType.backgroundUnlock,
      newLevel: newLevel,
      newXp: 0,
      unlockedBackground: unlockedBackground,
    );
  }
}

enum ProgressionCelebrationType { levelUp, rankUp, backgroundUnlock }

class ProgressionCelebrationService {
  static void showCelebration(
    BuildContext context,
    ProgressionCelebration celebration,
  ) {
    debugPrint(
      'ProgressionCelebrationService.showCelebration called: type=${celebration.type}, level=${celebration.newLevel}',
    );
    if (!context.mounted) {
      debugPrint('ProgressionCelebrationService: Context not mounted');
      return;
    }

    switch (celebration.type) {
      case ProgressionCelebrationType.levelUp:
        // Show level up, then background unlock if applicable (after level up closes)
        showLevelUp(
          context,
          newLevel: celebration.newLevel,
          newXp: celebration.newXp,
          onContinue: celebration.unlockedBackground != null
              ? () {
                  // Show background unlock after level up is closed
                  if (context.mounted) {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (context.mounted) {
                        showBackgroundUnlock(
                          context,
                          backgroundNumber: celebration.unlockedBackground!,
                          level: celebration.newLevel,
                        );
                      }
                    });
                  }
                }
              : null,
        );
        break;
      case ProgressionCelebrationType.backgroundUnlock:
        showBackgroundUnlock(
          context,
          backgroundNumber: celebration.unlockedBackground!,
          level: celebration.newLevel,
        );
        break;
      case ProgressionCelebrationType.rankUp:
        if (celebration.newRank != null) {
          // Show level up first, then rank up after closing
          showLevelUp(
            context,
            newLevel: celebration.newLevel,
            newXp: celebration.newXp,
            onContinue: () {
              // Show rank up after level up is closed
              if (context.mounted) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (context.mounted) {
                    showRankUp(
                      context,
                      newRank: celebration.newRank!,
                      newLevel: celebration.newLevel,
                    );
                  }
                });
              }
            },
          );
        }
        break;
    }
  }

  static void showLevelUp(
    BuildContext context, {
    required int newLevel,
    required int newXp,
    VoidCallback? onContinue,
  }) {
    debugPrint(
      'ProgressionCelebrationService.showLevelUp called: Level $newLevel, XP $newXp',
    );
    if (!context.mounted) {
      debugPrint('ProgressionCelebrationService.showLevelUp: Context not mounted');
      return;
    }
    CelebrationHelper.showLevelUp(
      context,
      title: 'Level Up! 🎉',
      subtitle: 'You reached Level $newLevel',
      description: 'You now have $newXp XP. Keep up the great work!',
      color: Colors.blue,
      buttonText: 'Close',
      onContinue: onContinue,
    );
  }

  static void showRankUp(
    BuildContext context, {
    required MartialRank newRank,
    required int newLevel,
    VoidCallback? onContinue,
  }) {
    final rankInfo = _getRankInfo(newRank);

    CelebrationHelper.showRankUp(
      context,
      title: 'Rank Up!',
      subtitle: 'You are now a ${rankInfo.name}',
      description:
          'Congratulations on reaching Level $newLevel and earning the ${rankInfo.name} rank!',
      color: rankInfo.color,
      martialRank: newRank,
      buttonText: 'Close',
      onContinue: onContinue,
    );
  }

  static void showBackgroundUnlock(
    BuildContext context, {
    required int backgroundNumber,
    required int level,
  }) {
    CelebrationHelper.showBackgroundUnlock(
      context,
      backgroundNumber: backgroundNumber,
      level: level,
    );
  }

  static void showGrandmasterAchievement(
    BuildContext context, {
    required int level,
  }) {
    CelebrationHelper.showRankUp(
      context,
      title: 'Grandmaster!',
      subtitle: 'You have reached the highest rank!',
      description:
          'Congratulations! You are now a Grandmaster at Level $level. This is the pinnacle of focus and dedication!',
      color: MartialRank.grandmaster.color,
      martialRank: MartialRank.grandmaster,
    );
  }

  static RankInfo _getRankInfo(MartialRank rank) {
    switch (rank) {
      case MartialRank.novice:
        return RankInfo('Novice', Colors.green, 'Beginner');
      case MartialRank.apprentice:
        return RankInfo('Apprentice', Colors.blue, 'Novice');
      case MartialRank.disciple:
        return RankInfo('Disciple', Colors.purple, 'Student');
      case MartialRank.adept:
        return RankInfo('Adept', Colors.orange, 'Practitioner');
      case MartialRank.master:
        return RankInfo('Master', Colors.red, 'Expert');
      case MartialRank.grandmaster:
        return RankInfo('Grandmaster', Colors.purple, 'Grandmaster');
    }
  }
}

class RankInfo {
  final String name;
  final Color color;
  final String description;

  const RankInfo(this.name, this.color, this.description);
}
