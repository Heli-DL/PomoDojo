import 'package:flutter_test/flutter_test.dart';
import 'package:pomodojo_app/features/progression/progression_model.dart';
import 'package:pomodojo_app/features/progression/martial_rank.dart';

void main() {
  group('ProgressionModel', () {
    group('levelFromXP', () {
      test('returns level 1 for XP less than 50', () {
        expect(ProgressionModel.levelFromXP(0), 1);
        expect(ProgressionModel.levelFromXP(49), 1);
      });

      test('returns correct level for XP thresholds', () {
        expect(ProgressionModel.levelFromXP(50), 2);
        expect(ProgressionModel.levelFromXP(149), 2);
        expect(ProgressionModel.levelFromXP(150), 3);
        expect(ProgressionModel.levelFromXP(299), 3);
        expect(ProgressionModel.levelFromXP(300), 4);
        expect(ProgressionModel.levelFromXP(499), 4);
        expect(ProgressionModel.levelFromXP(500), 5);
        expect(ProgressionModel.levelFromXP(799), 5);
        expect(ProgressionModel.levelFromXP(800), 6);
        expect(ProgressionModel.levelFromXP(1199), 6);
        expect(ProgressionModel.levelFromXP(1200), 7);
        expect(ProgressionModel.levelFromXP(1699), 7);
        expect(ProgressionModel.levelFromXP(1700), 8);
        expect(ProgressionModel.levelFromXP(2299), 8);
        expect(ProgressionModel.levelFromXP(2300), 9);
        expect(ProgressionModel.levelFromXP(2999), 9);
        expect(ProgressionModel.levelFromXP(3000), 10);
        expect(ProgressionModel.levelFromXP(3999), 10);
        expect(ProgressionModel.levelFromXP(4000), 11);
      });

      test('returns correct level for levels above 10', () {
        expect(ProgressionModel.levelFromXP(4000), 11);
        expect(ProgressionModel.levelFromXP(4999), 11);
        expect(ProgressionModel.levelFromXP(5000), 12);
        expect(ProgressionModel.levelFromXP(6000), 13);
        expect(ProgressionModel.levelFromXP(10000), 17);
        expect(ProgressionModel.levelFromXP(20000), 27);
      });
    });

    group('xpForLevel', () {
      test('returns correct XP for levels 1-10', () {
        expect(ProgressionModel.xpForLevel(1), 0);
        expect(ProgressionModel.xpForLevel(2), 50);
        expect(ProgressionModel.xpForLevel(3), 150);
        expect(ProgressionModel.xpForLevel(4), 300);
        expect(ProgressionModel.xpForLevel(5), 500);
        expect(ProgressionModel.xpForLevel(6), 800);
        expect(ProgressionModel.xpForLevel(7), 1200);
        expect(ProgressionModel.xpForLevel(8), 1700);
        expect(ProgressionModel.xpForLevel(9), 2300);
        expect(ProgressionModel.xpForLevel(10), 3000);
      });

      test('returns correct XP for level 11', () {
        expect(ProgressionModel.xpForLevel(11), 4000);
      });

      test('returns correct XP for levels above 11', () {
        expect(ProgressionModel.xpForLevel(12), 5000);
        expect(ProgressionModel.xpForLevel(13), 6000);
        expect(ProgressionModel.xpForLevel(20), 13000);
        // Level 50: 4000 + (50-11)*1000 = 4000 + 39000 = 43000
        expect(ProgressionModel.xpForLevel(50), 43000);
      });
    });

    group('xpForNextLevel getter', () {
      test('returns correct XP needed for next level', () {
        final model = ProgressionModel(
          level: 1,
          xp: 25,
          totalSessions: 0,
          rank: MartialRank.novice,
        );
        expect(model.xpForNextLevel, 50);

        final model2 = ProgressionModel(
          level: 5,
          xp: 600,
          totalSessions: 10,
          rank: MartialRank.disciple,
        );
        expect(model2.xpForNextLevel, 800);
      });
    });

    group('xpProgress getter', () {
      test('returns correct XP progress within current level', () {
        final model = ProgressionModel(
          level: 2,
          xp: 100,
          totalSessions: 5,
          rank: MartialRank.novice,
        );
        // Level 2 starts at 50 XP, so 100 - 50 = 50
        expect(model.xpProgress, 50);

        final model2 = ProgressionModel(
          level: 1,
          xp: 25,
          totalSessions: 2,
          rank: MartialRank.novice,
        );
        // Level 1 starts at 0 XP, so 25 - 0 = 25
        expect(model2.xpProgress, 25);
      });
    });

    group('xpNeeded getter', () {
      test('returns correct XP needed to reach next level', () {
        final model = ProgressionModel(
          level: 1,
          xp: 25,
          totalSessions: 2,
          rank: MartialRank.novice,
        );
        // Level 2 needs 50 XP, currently at 25, so need 25 more
        expect(model.xpNeeded, 25);

        final model2 = ProgressionModel(
          level: 3,
          xp: 200,
          totalSessions: 8,
          rank: MartialRank.apprentice,
        );
        // Level 4 needs 300 XP, currently at 200, so need 100 more
        expect(model2.xpNeeded, 100);
      });
    });

    group('progressPercentage getter', () {
      test('returns 0.0 for level start', () {
        final model = ProgressionModel(
          level: 2,
          xp: 50,
          totalSessions: 5,
          rank: MartialRank.novice,
        );
        expect(model.progressPercentage, 0.0);
      });

      test('returns 1.0 for level max', () {
        final model = ProgressionModel(
          level: 1,
          xp: 50,
          totalSessions: 5,
          rank: MartialRank.novice,
        );
        expect(model.progressPercentage, 1.0);
      });

      test('returns correct percentage for middle of level', () {
        final model = ProgressionModel(
          level: 2,
          xp: 100,
          totalSessions: 5,
          rank: MartialRank.novice,
        );
        // Level 2: 50-150 XP range, at 100 = 50% progress
        expect(model.progressPercentage, closeTo(0.5, 0.01));
      });
    });

    group('isRankUpgrade', () {
      test('returns true when rank increases', () {
        final previous = ProgressionModel(
          level: 2,
          xp: 50,
          totalSessions: 5,
          rank: MartialRank.novice,
        );
        final current = ProgressionModel(
          level: 3,
          xp: 150,
          totalSessions: 10,
          rank: MartialRank.apprentice,
        );
        expect(current.isRankUpgrade(previous), true);
      });

      test('returns false when rank stays same', () {
        final previous = ProgressionModel(
          level: 2,
          xp: 50,
          totalSessions: 5,
          rank: MartialRank.novice,
        );
        final current = ProgressionModel(
          level: 2,
          xp: 100,
          totalSessions: 8,
          rank: MartialRank.novice,
        );
        expect(current.isRankUpgrade(previous), false);
      });

      test('returns false when rank decreases (should not happen)', () {
        final previous = ProgressionModel(
          level: 5,
          xp: 500,
          totalSessions: 20,
          rank: MartialRank.disciple,
        );
        final current = ProgressionModel(
          level: 3,
          xp: 150,
          totalSessions: 10,
          rank: MartialRank.apprentice,
        );
        expect(current.isRankUpgrade(previous), false);
      });
    });

    group('fromStats factory', () {
      test('creates correct model from XP and sessions', () {
        final model = ProgressionModel.fromStats(100, 5);
        expect(model.level, 2);
        expect(model.xp, 100);
        expect(model.totalSessions, 5);
        expect(model.rank, MartialRank.novice);
      });

      test('creates correct model for higher levels', () {
        final model = ProgressionModel.fromStats(2500, 50);
        expect(model.level, 9);
        expect(model.xp, 2500);
        expect(model.totalSessions, 50);
        // Level 9 = Master rank (levels 9-10 are Master)
        expect(model.rank, MartialRank.master);
      });

      test('creates grandmaster for very high level', () {
        final model = ProgressionModel.fromStats(15000, 200);
        expect(model.level, greaterThan(10));
        expect(model.rank, MartialRank.grandmaster);
      });
    });

    group('equality', () {
      test('two models with same values are equal', () {
        final model1 = ProgressionModel(
          level: 5,
          xp: 600,
          totalSessions: 20,
          rank: MartialRank.disciple,
        );
        final model2 = ProgressionModel(
          level: 5,
          xp: 600,
          totalSessions: 20,
          rank: MartialRank.disciple,
        );
        expect(model1 == model2, true);
        expect(model1.hashCode, model2.hashCode);
      });

      test('two models with different values are not equal', () {
        final model1 = ProgressionModel(
          level: 5,
          xp: 600,
          totalSessions: 20,
          rank: MartialRank.disciple,
        );
        final model2 = ProgressionModel(
          level: 6,
          xp: 800,
          totalSessions: 25,
          rank: MartialRank.disciple,
        );
        expect(model1 == model2, false);
      });
    });
  });
}
