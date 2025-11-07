import 'package:flutter/material.dart';
import '../../progression/progression_model.dart';

/// Displays rank/level, dialogue, a progress bar, and XP/sessions.
/// Replace `dynamic` with your actual `ProgressionModel` type and add the import.
class CharacterProgressionCard extends StatelessWidget {
  const CharacterProgressionCard({
    super.key,
    required this.progression, // e.g. ProgressionModel
    this.accentColor = const Color(0xFFFFC107),
    this.barBackgroundColor = const Color(0xFF404040),
    this.borderRadius = 16,
    this.barHeight = 8,
    this.padding = const EdgeInsets.all(16),
  });

  final ProgressionModel progression;
  final Color accentColor;
  final Color barBackgroundColor;
  final double borderRadius;
  final double barHeight;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    // Pull themed colors with fallbacks
    final theme = Theme.of(context);
    final Color cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final Color titleColor =
        theme.textTheme.titleLarge?.color ?? theme.colorScheme.onSurface;
    final Color bodyColor =
        theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurfaceVariant;

    // Safely coerce the progress into a 0..1 range
    final double progress =
        (progression.progressPercentage as num?)?.toDouble() ?? 0.0;
    final double clamped = progress.clamp(0.0, 1.0);

    return Card(
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank and Level
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  progression.rank.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                Text(
                  'Level ${progression.level}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Description (dialogue)
            Text(
              progression.rank.dialogue,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: bodyColor),
            ),

            const SizedBox(height: 16),

            // Progress Bar
            SizedBox(
              height: barHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: barBackgroundColor,
                  borderRadius: BorderRadius.circular(barHeight / 2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: clamped,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(barHeight / 2),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // XP and Sessions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progression.xp} XP',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: bodyColor),
                ),
                Text(
                  '${progression.totalSessions} Sessions',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: bodyColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
