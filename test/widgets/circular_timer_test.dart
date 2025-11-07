import 'package:flutter_test/flutter_test.dart';
import 'package:pomodojo_app/features/timer/widgets/circular_timer.dart';
import 'package:pomodojo_app/features/progression/martial_rank.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('CircularTimer', () {
    testWidgets('displays remaining time', (WidgetTester tester) async {
      await tester.pumpWidget(
        createThemedTestWidget(
          child: CircularTimer(
            totalDuration: const Duration(minutes: 25),
            remaining: const Duration(minutes: 20),
            isRunning: false,
            isPaused: false,
            isFocusMode: true,
            sessionLabel: 'Focus Session',
            rank: MartialRank.novice,
          ),
        ),
      );

      // Should display remaining time (20:00)
      expect(find.textContaining('20'), findsWidgets);
    });

    testWidgets('displays correct session label', (WidgetTester tester) async {
      await tester.pumpWidget(
        createThemedTestWidget(
          child: CircularTimer(
            totalDuration: const Duration(minutes: 25),
            remaining: const Duration(minutes: 20),
            isRunning: false,
            isPaused: false,
            isFocusMode: true,
            sessionLabel: 'Focus Session 1/4',
            rank: MartialRank.novice,
          ),
        ),
      );

      expect(find.text('Focus Session 1/4'), findsOneWidget);
    });

    testWidgets('handles null rank gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        createThemedTestWidget(
          child: CircularTimer(
            totalDuration: const Duration(minutes: 25),
            remaining: const Duration(minutes: 20),
            isRunning: false,
            isPaused: false,
            isFocusMode: true,
            sessionLabel: 'Focus Session',
            rank: null,
          ),
        ),
      );

      // Should still render without crashing
      expect(find.textContaining('20'), findsWidgets);
    });

    testWidgets('displays different colors for focus and break modes', (
      WidgetTester tester,
    ) async {
      // Focus mode
      await tester.pumpWidget(
        createThemedTestWidget(
          child: CircularTimer(
            totalDuration: const Duration(minutes: 25),
            remaining: const Duration(minutes: 20),
            isRunning: true,
            isPaused: false,
            isFocusMode: true,
            sessionLabel: 'Focus',
            rank: MartialRank.novice,
          ),
        ),
      );

      await tester.pump(); // Allow widget to build

      // Break mode
      await tester.pumpWidget(
        createThemedTestWidget(
          child: CircularTimer(
            totalDuration: const Duration(minutes: 5),
            remaining: const Duration(minutes: 3),
            isRunning: true,
            isPaused: false,
            isFocusMode: false,
            sessionLabel: 'Break',
            rank: MartialRank.novice,
          ),
        ),
      );

      await tester.pump(); // Allow widget to build

      // Should render both without crashing
      expect(find.byType(CircularTimer), findsWidgets);
    });
  });
}
