import 'package:flutter_test/flutter_test.dart';
import 'package:pomodojo_app/widgets/progression_header.dart';
import 'package:pomodojo_app/features/progression/progression_model.dart';
import 'package:pomodojo_app/features/progression/martial_rank.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('ProgressionHeader', () {
    testWidgets('displays level and rank correctly', (
      WidgetTester tester,
    ) async {
      const progression = ProgressionModel(
        level: 5,
        xp: 600,
        totalSessions: 20,
        rank: MartialRank.disciple,
      );

      await tester.pumpWidget(
        createTestWidget(
          child: ProgressionHeader(progression: progression, flames: 5),
        ),
      );

      // Check that level is displayed
      expect(find.text('5'), findsWidgets);

      // Check that rank name is displayed
      expect(find.text('Disciple'), findsOneWidget);
    });

    testWidgets('displays flames count', (WidgetTester tester) async {
      const progression = ProgressionModel(
        level: 3,
        xp: 200,
        totalSessions: 10,
        rank: MartialRank.apprentice,
      );

      await tester.pumpWidget(
        createTestWidget(
          child: ProgressionHeader(progression: progression, flames: 7),
        ),
      );

      // Check that flames count is displayed
      expect(find.text('7'), findsWidgets);
    });

    testWidgets('handles zero flames', (WidgetTester tester) async {
      const progression = ProgressionModel(
        level: 1,
        xp: 0,
        totalSessions: 0,
        rank: MartialRank.novice,
      );

      await tester.pumpWidget(
        createTestWidget(
          child: ProgressionHeader(progression: progression, flames: 0),
        ),
      );

      expect(find.text('0'), findsWidgets);
    });
  });
}
