import 'package:flutter/material.dart';

/// A round stop button for the timer, positioned separately from the circular timer.
/// Always red in color regardless of theme.
class TimerStopButton extends StatelessWidget {
  const TimerStopButton({
    super.key,
    required this.onStop,
    this.size = 48, // WCAG 2.2 minimum tap target size
    this.isVisible = true,
  });

  final VoidCallback onStop;
  final double size;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Semantics(
      label: 'Stop timer',
      hint: 'Double tap to stop the current session',
      button: true,
      enabled: true,
      child: GestureDetector(
        onTap: onStop,
        child: Material(
          color: Colors.red,
          shape: const CircleBorder(),
          elevation: 2,
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Colors.red, // Always red regardless of theme
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stop,
              color: Colors.white, // Always white for contrast
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
