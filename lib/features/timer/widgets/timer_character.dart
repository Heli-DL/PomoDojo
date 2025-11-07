import 'package:flutter/material.dart';
import '../timer_state.dart';
import '../pomodoro_session.dart';
import '../../progression/martial_rank.dart';

class TimerCharacter extends StatelessWidget {
  final TimerState timerState;
  final MartialRank rank;

  const TimerCharacter({
    super.key,
    required this.timerState,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    // Determine which image to show - optimized logic
    final String imageSuffix;
    final sessionType = timerState.pomodoroSession?.currentSessionType;
    final isBreak =
        sessionType == PomodoroSessionType.shortBreak ||
        sessionType == PomodoroSessionType.longBreak;

    // Show sitting pose (1) when timer hasn't started OR when timer reaches 0
    if (timerState.totalDuration == Duration.zero ||
        timerState.remaining <= Duration.zero) {
      // Not started or completed - show sitting pose (1)
      imageSuffix = '_1.png';
    } else if (isBreak) {
      // Break session - show break pose (3)
      imageSuffix = '_3.png';
    } else {
      // Focus session - show focusing pose (2)
      imageSuffix = '_2.png';
    }

    // Get rank name for file path
    final rankName = rank.name.toLowerCase();
    final imagePath = 'assets/images/$rankName$imageSuffix';

    return Image.asset(
      imagePath,
      cacheWidth: 200, // Optimize memory usage
      cacheHeight: 200,
      errorBuilder: (context, error, stackTrace) {
        // Return a placeholder if image doesn't exist
        return Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: rank.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(rank.icon, size: 96, color: rank.color),
        );
      },
      fit: BoxFit.contain,
      width: 200,
      height: 200,
    );
  }
}
