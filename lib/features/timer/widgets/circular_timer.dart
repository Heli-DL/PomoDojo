import 'package:flutter/material.dart';
import '../../progression/martial_rank.dart';

/// A circular timer with progress ring + labels.
/// Provide the total/remaining durations, running state, and labels.
/// (No external helpers required.)
class CircularTimer extends StatelessWidget {
  const CircularTimer({
    super.key,
    required this.totalDuration,
    required this.remaining,
    required this.isRunning,
    required this.isFocusMode,
    required this.sessionLabel, // e.g. "Focus", "Short break", etc.
    this.isPaused = false,
    this.size = 250,
    this.rank,
  });

  final Duration totalDuration;
  final Duration remaining;
  final bool isRunning;
  final bool isFocusMode;
  final String sessionLabel;
  final bool isPaused;
  final MartialRank? rank;

  /// Diameter of the circle.
  final double size;

  // Generate glow effects based on rank
  // Reduced blur/spread to stay within timer boundaries
  List<BoxShadow> _getGlowShadows(MartialRank? rank, bool isFocusMode) {
    if (!isFocusMode || rank == null) {
      return const []; // No glow for breaks or when rank is unknown
    }

    // Novice: grey glow - more visible and distinct
    if (rank == MartialRank.novice) {
      return [
        BoxShadow(
          color: const Color(
            0xFF9E9E9E,
          ).withValues(alpha: 0.85), // Brighter grey for better visibility
          blurRadius: 18,
          spreadRadius: 3,
        ),
        BoxShadow(
          color: const Color(
            0xFFBDBDBD,
          ).withValues(alpha: 0.5), // Lighter grey accent
          blurRadius: 22,
          spreadRadius: 1.5,
        ),
      ];
    }

    // Apprentice: orange glow - vibrant and distinct
    if (rank == MartialRank.apprentice) {
      return [
        BoxShadow(
          color: const Color(
            0xFFFF6B00,
          ).withValues(alpha: 0.7), // Vibrant orange
          blurRadius: 18,
          spreadRadius: 3,
        ),
        BoxShadow(
          color: const Color(
            0xFFFF6B00,
          ).withValues(alpha: 0.4), // Orange accent
          blurRadius: 22,
          spreadRadius: 1.5,
        ),
      ];
    }

    // Disciple: copper glow - warm and distinct
    if (rank == MartialRank.disciple) {
      return [
        BoxShadow(
          color: const Color(0xFFB87333).withValues(alpha: 0.75), // Rich copper
          blurRadius: 20,
          spreadRadius: 3.5,
        ),
        BoxShadow(
          color: const Color(
            0xFFCD7F32,
          ).withValues(alpha: 0.5), // Lighter copper accent
          blurRadius: 24,
          spreadRadius: 2,
        ),
      ];
    }

    // Adept: gold glow - bright and prominent
    if (rank == MartialRank.adept) {
      return [
        BoxShadow(
          color: const Color(0xFFFFD700).withValues(alpha: 0.8), // Bright gold
          blurRadius: 22,
          spreadRadius: 4,
        ),
        BoxShadow(
          color: const Color(
            0xFFFFE44D,
          ).withValues(alpha: 0.6), // Lighter gold accent
          blurRadius: 26,
          spreadRadius: 2.5,
        ),
      ];
    }

    // Grandmaster: purple inner ring, golden outer ring - highly distinguished
    if (rank == MartialRank.grandmaster) {
      return [
        // Inner purple ring - smaller blur/spread for inner circle - very vibrant
        BoxShadow(
          color: const Color(
            0xFF8E44AD,
          ).withValues(alpha: 0.85), // Bright purple
          blurRadius: 14,
          spreadRadius: 1.5,
        ),
        BoxShadow(
          color: const Color(
            0xFF9B59B6,
          ).withValues(alpha: 0.7), // Purple accent
          blurRadius: 18,
          spreadRadius: 0.5,
        ),
        // Outer golden ring - larger blur/spread for outer circle - bright gold
        BoxShadow(
          color: const Color(0xFFFFD700).withValues(alpha: 0.75), // Bright gold
          blurRadius: 28,
          spreadRadius: 4,
        ),
        BoxShadow(
          color: const Color(
            0xFFFFE44D,
          ).withValues(alpha: 0.6), // Lighter gold accent
          blurRadius: 32,
          spreadRadius: 2,
        ),
      ];
    }

    // Master: burgundy inner ring, golden outer ring - highly distinguished
    if (rank == MartialRank.master) {
      return [
        // Inner burgundy ring - smaller blur/spread for inner circle - deep burgundy
        BoxShadow(
          color: const Color(
            0xFF800020,
          ).withValues(alpha: 0.8), // Deep burgundy
          blurRadius: 12,
          spreadRadius: 1.5,
        ),
        BoxShadow(
          color: const Color(
            0xFFA00030,
          ).withValues(alpha: 0.65), // Lighter burgundy accent
          blurRadius: 16,
          spreadRadius: 0.5,
        ),
        // Outer golden ring - larger blur/spread for outer circle - bright gold
        BoxShadow(
          color: const Color(0xFFFFD700).withValues(alpha: 0.7), // Bright gold
          blurRadius: 25,
          spreadRadius: 3.5,
        ),
        BoxShadow(
          color: const Color(
            0xFFFFE44D,
          ).withValues(alpha: 0.55), // Lighter gold accent
          blurRadius: 29,
          spreadRadius: 2,
        ),
      ];
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double progress = totalDuration > Duration.zero
        ? remaining.inSeconds / totalDuration.inSeconds
        : 1.0;

    // Use theme colors for different modes
    final Color progressColor = isFocusMode
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;
    final Color backgroundColor = theme.colorScheme.surface;

    // Accessibility labels
    final String remainingText = _formatDuration(remaining);
    final String statusText = isRunning
        ? '$sessionLabel running'
        : (isPaused)
        ? '$sessionLabel paused'
        : '$sessionLabel ready';
    final double percentComplete = (1.0 - progress.clamp(0.0, 1.0)) * 100;

    return Semantics(
      label:
          '$statusText. $remainingText remaining. ${percentComplete.toStringAsFixed(0)}% complete.',
      value: remainingText,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect behind the timer (only when focus session is running)
          if (isFocusMode && rank != null && isRunning)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Subtle fill so glow is visible
                color: rank!.color.withValues(alpha: 0.08),
                boxShadow: _getGlowShadows(rank, isFocusMode),
              ),
            ),

          // Background circle
          Material(
            color: backgroundColor,
            shape: const CircleBorder(),
            elevation: 1,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Progress circle - always show the ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: totalDuration == Duration.zero
                  ? 1.0 // Show full ring when timer not started
                  : progress.clamp(0.0, 1.0),
              strokeWidth: 16,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              semanticsLabel:
                  'Progress: ${percentComplete.toStringAsFixed(0)}%',
              semanticsValue: '$percentComplete percent',
            ),
          ),

          // Timer text + label (moved up to avoid overlap with character)
          Transform.translate(
            offset: const Offset(0, -12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  sessionLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 10, // Fixed size to prevent overflow
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                Text(
                  remainingText,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    fontSize: 48, // Fixed size to prevent overflow
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Local formatter to avoid external deps
  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}
