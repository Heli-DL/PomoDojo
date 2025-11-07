import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/timer/timer_controller.dart';
import '../accessibility/focus_outline.dart';

class CentralButton extends ConsumerWidget {
  const CentralButton({
    super.key,
    this.size = 60,
    this.homeRoute = '/',
    this.selectionRoute = '/timer-mode',
  });

  final double size;
  final String homeRoute;
  final String selectionRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final isHome = currentLocation == homeRoute;
    final isTimerMode = currentLocation == selectionRoute;

    // Watch timer state to determine if running or paused
    final timerState = ref.watch(timerControllerProvider);
    final isTimerRunning = timerState.isRunning;
    final isTimerPaused = timerState.isPaused;

    // Always show the button since we now have a default recommended preset
    final timerController = ref.read(timerControllerProvider.notifier);

    // Accessibility labels
    String buttonLabel;
    String buttonHint;
    if (isTimerRunning) {
      buttonLabel = 'Pause timer';
      buttonHint = 'Double tap to pause the current session';
    } else if (isTimerPaused) {
      buttonLabel = 'Resume timer';
      buttonHint = 'Double tap to resume the paused session';
    } else if (isHome || isTimerMode) {
      buttonLabel = 'Start timer';
      buttonHint = 'Double tap to start a focus session';
    } else {
      buttonLabel = 'Select timer mode';
      buttonHint = 'Double tap to choose a timer preset';
    }

    return Semantics(
      label: buttonLabel,
      hint: buttonHint,
      button: true,
      enabled: true,
      child: FocusOutline(
        borderRadius: BorderRadius.circular(size / 2),
        padding: const EdgeInsets.all(3),
        child: GestureDetector(
          onTap: () {
            // If timer is running, pause it
            if (isTimerRunning) {
              timerController.pause();
              return;
            }

            // If timer is paused, resume it
            if (isTimerPaused) {
              timerController.resume();
              return;
            }

            // Check if there's a queued session (like a break) that doesn't need topic selection
            if (timerState.pomodoroSession != null &&
                !timerState.isRunning &&
                !timerState.isPaused &&
                timerState.remaining > Duration.zero) {
              // Start the queued session (e.g., break after focus)
              timerController.continueSession();
              return;
            }

            if (isTimerMode) {
              context.go('/topic-selection');
            } else if (isHome) {
              context.go('/topic-selection');
            } else {
              // On other screens, navigate to timer-mode to pick
              context.go(selectionRoute);
            }
          },
          child: Material(
            // Always use primary (teal) color when showing play button, secondary only for pause
            color: isTimerRunning
                ? theme.colorScheme.secondary
                : theme.colorScheme.primary,
            shape: const CircleBorder(),
            elevation: 3,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                // Always use primary (teal) color when showing play button, secondary only for pause
                color: isTimerRunning
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTimerRunning ? Icons.pause : Icons.play_arrow,
                color: isTimerRunning
                    ? theme.colorScheme.onSecondary
                    : theme.colorScheme.onPrimary,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
