import 'package:flutter_test/flutter_test.dart';
import 'package:pomodojo_app/features/timer/pomodoro_session.dart';
import 'package:pomodojo_app/features/timer/pomodoro_presets.dart';

void main() {
  group('PomodoroSession', () {
    group('initial factory', () {
      test('creates initial session with correct defaults', () {
        final session = PomodoroSession.initial(PomodoroPreset.classic);
        
        expect(session.preset, PomodoroPreset.classic);
        expect(session.currentSessionType, PomodoroSessionType.focus);
        expect(session.currentCycle, 1);
        expect(session.completedCycles, 0);
        expect(session.sessionDuration, PomodoroPreset.classic.focus);
        expect(session.remainingTime, PomodoroPreset.classic.focus);
        expect(session.isRunning, false);
        expect(session.sessionStartTime, null);
        expect(session.sessionEndTime, null);
      });

      test('creates initial session with topic information', () {
        const topicId = 'topic_123';
        const topicName = 'Programming';
        final session = PomodoroSession.initial(
          PomodoroPreset.classic,
          topicId: topicId,
          topicName: topicName,
        );
        
        expect(session.topicId, topicId);
        expect(session.topicName, topicName);
      });
    });

    group('start', () {
      test('sets isRunning to true and sessionStartTime', () {
        final session = PomodoroSession.initial(PomodoroPreset.classic);
        final started = session.start();
        
        expect(started.isRunning, true);
        expect(started.sessionStartTime, isNotNull);
      });

      test('preserves other properties', () {
        final session = PomodoroSession.initial(PomodoroPreset.classic);
        final started = session.start();
        
        expect(started.preset, session.preset);
        expect(started.currentSessionType, session.currentSessionType);
        expect(started.currentCycle, session.currentCycle);
      });
    });

    group('stop', () {
      test('sets isRunning to false and sessionEndTime', () {
        final session = PomodoroSession.initial(PomodoroPreset.classic)
            .start();
        final stopped = session.stop();
        
        expect(stopped.isRunning, false);
        expect(stopped.sessionEndTime, isNotNull);
      });
    });

    group('completeSession', () {
      test('moves from focus to short break after first cycle', () {
        final session = PomodoroSession.initial(PomodoroPreset.classic);
        final completed = session.completeSession();
        
        expect(completed.currentSessionType, PomodoroSessionType.shortBreak);
        expect(completed.currentCycle, 2);
        expect(completed.sessionDuration, PomodoroPreset.classic.shortBreak);
        expect(completed.completedCycles, 0);
      });

      test('moves from short break to focus session', () {
        final session = PomodoroSession(
          preset: PomodoroPreset.classic,
          currentSessionType: PomodoroSessionType.shortBreak,
          currentCycle: 2,
          completedCycles: 0,
          sessionDuration: PomodoroPreset.classic.shortBreak,
          remainingTime: PomodoroPreset.classic.shortBreak,
          isRunning: false,
        );
        final completed = session.completeSession();
        
        expect(completed.currentSessionType, PomodoroSessionType.focus);
        expect(completed.currentCycle, 2); // Cycle stays same after break
        expect(completed.sessionDuration, PomodoroPreset.classic.focus);
      });

      test('moves to long break after completing required cycles', () {
        // Classic preset: long break after 4 cycles
        final session = PomodoroSession(
          preset: PomodoroPreset.classic,
          currentSessionType: PomodoroSessionType.focus,
          currentCycle: 4, // Last focus cycle before long break
          completedCycles: 0,
          sessionDuration: PomodoroPreset.classic.focus,
          remainingTime: PomodoroPreset.classic.focus,
          isRunning: false,
        );
        final completed = session.completeSession();
        
        expect(completed.currentSessionType, PomodoroSessionType.longBreak);
        expect(completed.currentCycle, 1); // Cycle resets
        expect(completed.completedCycles, 1); // Increments
        expect(completed.sessionDuration, PomodoroPreset.classic.longBreak);
      });

      test('resets after long break', () {
        final session = PomodoroSession(
          preset: PomodoroPreset.classic,
          currentSessionType: PomodoroSessionType.longBreak,
          currentCycle: 1,
          completedCycles: 1,
          sessionDuration: PomodoroPreset.classic.longBreak,
          remainingTime: PomodoroPreset.classic.longBreak,
          isRunning: false,
        );
        final completed = session.completeSession();
        
        expect(completed.currentSessionType, PomodoroSessionType.focus);
        expect(completed.currentCycle, 1); // Cycle resets to 1
        expect(completed.sessionDuration, PomodoroPreset.classic.focus);
      });
    });

    group('updateRemainingTime', () {
      test('updates remaining time', () {
        final session = PomodoroSession.initial(PomodoroPreset.classic);
        const newRemaining = Duration(minutes: 10);
        final updated = session.updateRemainingTime(newRemaining);
        
        expect(updated.remainingTime, newRemaining);
      });
    });

    group('sessionTypeName', () {
      test('returns correct name for each session type', () {
        final focusSession = PomodoroSession.initial(PomodoroPreset.classic);
        expect(focusSession.sessionTypeName, 'Focus');

        final shortBreakSession = PomodoroSession(
          preset: PomodoroPreset.classic,
          currentSessionType: PomodoroSessionType.shortBreak,
          currentCycle: 1,
          completedCycles: 0,
          sessionDuration: PomodoroPreset.classic.shortBreak,
          remainingTime: PomodoroPreset.classic.shortBreak,
          isRunning: false,
        );
        expect(shortBreakSession.sessionTypeName, 'Short Break');

        final longBreakSession = PomodoroSession(
          preset: PomodoroPreset.classic,
          currentSessionType: PomodoroSessionType.longBreak,
          currentCycle: 1,
          completedCycles: 1,
          sessionDuration: PomodoroPreset.classic.longBreak,
          remainingTime: PomodoroPreset.classic.longBreak,
          isRunning: false,
        );
        expect(longBreakSession.sessionTypeName, 'Long Break');
      });
    });

    group('sessionTypeDescription', () {
      test('returns correct description for focus session', () {
        final session = PomodoroSession(
          preset: PomodoroPreset.classic,
          currentSessionType: PomodoroSessionType.focus,
          currentCycle: 2,
          completedCycles: 0,
          sessionDuration: PomodoroPreset.classic.focus,
          remainingTime: PomodoroPreset.classic.focus,
          isRunning: false,
        );
        expect(session.sessionTypeDescription, 'Focus Session 2/4');
      });

      test('returns correct description for short break', () {
        final session = PomodoroSession(
          preset: PomodoroPreset.classic,
          currentSessionType: PomodoroSessionType.shortBreak,
          currentCycle: 2,
          completedCycles: 0,
          sessionDuration: PomodoroPreset.classic.shortBreak,
          remainingTime: PomodoroPreset.classic.shortBreak,
          isRunning: false,
        );
        expect(session.sessionTypeDescription, 'Short Break');
      });

      test('returns correct description for long break', () {
        final session = PomodoroSession(
          preset: PomodoroPreset.classic,
          currentSessionType: PomodoroSessionType.longBreak,
          currentCycle: 1,
          completedCycles: 2,
          sessionDuration: PomodoroPreset.classic.longBreak,
          remainingTime: PomodoroPreset.classic.longBreak,
          isRunning: false,
        );
        expect(session.sessionTypeDescription, 'Long Break - Cycle 2 Completed');
      });
    });

    group('progressPercentage', () {
      test('returns 0.0 at start', () {
        final session = PomodoroSession.initial(PomodoroPreset.classic);
        expect(session.progressPercentage, 0.0);
      });

      test('returns 1.0 when time is up', () {
        final session = PomodoroSession(
          preset: PomodoroPreset.classic,
          currentSessionType: PomodoroSessionType.focus,
          currentCycle: 1,
          completedCycles: 0,
          sessionDuration: const Duration(minutes: 25),
          remainingTime: Duration.zero,
          isRunning: false,
        );
        expect(session.progressPercentage, 1.0);
      });

      test('returns correct percentage for middle of session', () {
        final session = PomodoroSession(
          preset: PomodoroPreset.classic,
          currentSessionType: PomodoroSessionType.focus,
          currentCycle: 1,
          completedCycles: 0,
          sessionDuration: const Duration(minutes: 25),
          remainingTime: const Duration(minutes: 12, seconds: 30),
          isRunning: false,
        );
        // 12.5 minutes elapsed out of 25 = 50%
        expect(session.progressPercentage, closeTo(0.5, 0.01));
      });
    });

    group('isQuickSession', () {
      test('returns true for quick session preset', () {
        final quickPreset = const PomodoroPreset(
          id: 'quick_session',
          name: 'Quick',
          description: 'Quick session',
          focus: Duration(minutes: 15),
          shortBreak: Duration(minutes: 3),
          longBreak: Duration(minutes: 10),
          longBreakAfterCycles: 4,
        );
        final session = PomodoroSession.initial(quickPreset);
        expect(session.isQuickSession, true);
      });

      test('returns false for regular presets', () {
        final session = PomodoroSession.initial(PomodoroPreset.classic);
        expect(session.isQuickSession, false);
      });
    });

    group('copyWith', () {
      test('creates copy with updated properties', () {
        final original = PomodoroSession.initial(PomodoroPreset.classic);
        final copy = original.copyWith(
          currentCycle: 2,
          isRunning: true,
        );
        
        expect(copy.currentCycle, 2);
        expect(copy.isRunning, true);
        expect(copy.preset, original.preset);
        expect(copy.currentSessionType, original.currentSessionType);
      });
    });
  });
}

