import 'martial_rank.dart';

class ProgressionModel {
  final int level;
  final int xp;
  final int totalSessions;
  final MartialRank rank;

  const ProgressionModel({
    required this.level,
    required this.xp,
    required this.totalSessions,
    required this.rank,
  });

  // Calculate level from XP
  // Uses <= to handle exact boundary cases (e.g., 150 XP = level 3)
  static int levelFromXP(int xp) {
    if (xp < 50) return 1;
    if (xp <= 149) return 2;  // Changed to <= so 150 triggers level 3
    if (xp <= 299) return 3;  // Changed to <= so 300 triggers level 4
    if (xp <= 499) return 4;
    if (xp <= 799) return 5;
    if (xp <= 1199) return 6;
    if (xp <= 1699) return 7;
    if (xp <= 2299) return 8;
    if (xp <= 2999) return 9;
    if (xp <= 3999) return 10;

    // After level 10: each level +1000 XP
    // For level 11+, we need >= 4000 XP
    int remainingXP = xp - 4000;
    return 11 + (remainingXP ~/ 1000);
  }

  // Calculate XP needed for next level
  static int xpForLevel(int level) {
    switch (level) {
      case 1:
        return 0;
      case 2:
        return 50;
      case 3:
        return 150;
      case 4:
        return 300;
      case 5:
        return 500;
      case 6:
        return 800;
      case 7:
        return 1200;
      case 8:
        return 1700;
      case 9:
        return 2300;
      case 10:
        return 3000;
      default:
        if (level <= 11) return 4000;
        return 4000 + ((level - 11) * 1000);
    }
  }

  // XP needed for next level
  int get xpForNextLevel {
    return xpForLevel(level + 1);
  }

  // XP progress towards next level
  int get xpProgress {
    return xp - xpForLevel(level);
  }

  // XP needed to reach next level
  int get xpNeeded {
    return xpForNextLevel - xp;
  }

  // Progress percentage (0.0 to 1.0)
  double get progressPercentage {
    int currentLevelXP = xpForLevel(level);
    int nextLevelXP = xpForLevel(level + 1);

    if (nextLevelXP == currentLevelXP) return 1.0;

    return (xp - currentLevelXP) / (nextLevelXP - currentLevelXP);
  }

  // Check if rank just upgraded
  bool isRankUpgrade(ProgressionModel previous) {
    return rank != previous.rank && rank.index > previous.rank.index;
  }

  // Create from XP and sessions
  factory ProgressionModel.fromStats(int xp, int totalSessions) {
    final level = levelFromXP(xp);
    final rank = MartialRank.fromLevel(level);

    return ProgressionModel(
      level: level,
      xp: xp,
      totalSessions: totalSessions,
      rank: rank,
    );
  }

  @override
  String toString() {
    return 'ProgressionModel(level: $level, xp: $xp, sessions: $totalSessions, rank: ${rank.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProgressionModel &&
        other.level == level &&
        other.xp == xp &&
        other.totalSessions == totalSessions &&
        other.rank == rank;
  }

  @override
  int get hashCode {
    return Object.hash(level, xp, totalSessions, rank);
  }
}
