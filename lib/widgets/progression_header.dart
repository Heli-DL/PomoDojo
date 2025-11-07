import 'package:flutter/material.dart';
import '../features/progression/progression_model.dart';

class ProgressionHeader extends StatelessWidget {
  const ProgressionHeader({
    super.key,
    required this.progression,
    this.flames = 0,
  });

  final ProgressionModel progression;
  final int flames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Rank
            Row(
              children: [
                Icon(
                  progression.rank.icon,
                  color: progression.rank.color,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  progression.rank.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: progression.rank.color,
                  ),
                ),
              ],
            ),
            // Right: Streak
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '$flames',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Center: Level - absolutely centered using positioned
        Center(
          child: Text(
            'Level ${progression.level}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
