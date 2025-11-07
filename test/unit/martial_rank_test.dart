import 'package:flutter_test/flutter_test.dart';
import 'package:pomodojo_app/features/progression/martial_rank.dart';

void main() {
  group('MartialRank', () {
    group('fromLevel', () {
      test('returns novice for levels 1-2', () {
        expect(MartialRank.fromLevel(1), MartialRank.novice);
        expect(MartialRank.fromLevel(2), MartialRank.novice);
      });

      test('returns apprentice for levels 3-4', () {
        expect(MartialRank.fromLevel(3), MartialRank.apprentice);
        expect(MartialRank.fromLevel(4), MartialRank.apprentice);
      });

      test('returns disciple for levels 5-6', () {
        expect(MartialRank.fromLevel(5), MartialRank.disciple);
        expect(MartialRank.fromLevel(6), MartialRank.disciple);
      });

      test('returns adept for levels 7-8', () {
        expect(MartialRank.fromLevel(7), MartialRank.adept);
        expect(MartialRank.fromLevel(8), MartialRank.adept);
      });

      test('returns master for levels 9-10', () {
        expect(MartialRank.fromLevel(9), MartialRank.master);
        expect(MartialRank.fromLevel(10), MartialRank.master);
      });

      test('returns grandmaster for levels 11+', () {
        expect(MartialRank.fromLevel(11), MartialRank.grandmaster);
        expect(MartialRank.fromLevel(50), MartialRank.grandmaster);
        expect(MartialRank.fromLevel(100), MartialRank.grandmaster);
      });
    });

    group('properties', () {
      test('each rank has correct level range', () {
        expect(MartialRank.novice.levelRange, (1, 2));
        expect(MartialRank.apprentice.levelRange, (3, 4));
        expect(MartialRank.disciple.levelRange, (5, 6));
        expect(MartialRank.adept.levelRange, (7, 8));
        expect(MartialRank.master.levelRange, (9, 10));
        expect(MartialRank.grandmaster.levelRange, (11, 999));
      });

      test('each rank has dialogue', () {
        expect(MartialRank.novice.dialogue, isNotEmpty);
        expect(MartialRank.apprentice.dialogue, isNotEmpty);
        expect(MartialRank.disciple.dialogue, isNotEmpty);
        expect(MartialRank.adept.dialogue, isNotEmpty);
        expect(MartialRank.master.dialogue, isNotEmpty);
        expect(MartialRank.grandmaster.dialogue, isNotEmpty);
      });

      test('each rank has color', () {
        expect(MartialRank.novice.color, isNotNull);
        expect(MartialRank.apprentice.color, isNotNull);
        expect(MartialRank.disciple.color, isNotNull);
        expect(MartialRank.adept.color, isNotNull);
        expect(MartialRank.master.color, isNotNull);
        expect(MartialRank.grandmaster.color, isNotNull);
      });
    });
  });
}
