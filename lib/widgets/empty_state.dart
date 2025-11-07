import 'package:flutter/material.dart';

/// Reusable empty state widget for when lists/sections have no data
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: action,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state for achievements
class EmptyAchievementsState extends StatelessWidget {
  const EmptyAchievementsState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.emoji_events_outlined,
      title: 'No Achievements Yet',
      message:
          'Start completing Pomodoro sessions to unlock your first achievement! Each session brings you closer to greatness. 🥋',
    );
  }
}

/// Empty state for statistics
class EmptyStatsState extends StatelessWidget {
  const EmptyStatsState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.bar_chart_outlined,
      title: 'No Statistics Yet',
      message:
          'Complete your first Pomodoro session to start tracking your productivity statistics! 📊',
    );
  }
}

/// Empty state for topics
class EmptyTopicsState extends StatelessWidget {
  const EmptyTopicsState({super.key, this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.label_outline,
      title: 'No Topics Yet',
      message:
          'Create topics to organize and track your sessions by category. This helps you understand where you spend your focused time.',
      action: onAdd,
      actionLabel: 'Create Topic',
    );
  }
}
