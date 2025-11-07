import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/tasks/task_controller.dart';
import '../features/tasks/task_model.dart';
import '../features/timer/timer_controller.dart';
import '../features/timer/timer_mode_screen.dart';
import '../features/topics/topic_controller.dart';
import '../features/topics/topic_model.dart';

class TaskList extends ConsumerWidget {
  const TaskList({super.key, this.limit, this.onViewAll});

  final int? limit;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTasks = ref.watch(filteredTasksProvider);
    final controller = ref.read(taskListControllerProvider.notifier);
    final theme = Theme.of(context);

    return asyncTasks.when(
      data: (tasks) {
        final displayed = limit != null && tasks.length > limit!
            ? tasks.take(limit!).toList()
            : tasks;

        if (displayed.isEmpty) {
          return _EmptyTasks(onViewAll: onViewAll);
        }

        return Column(
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayed.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = displayed[index];
                return _TaskTile(
                  task: task,
                  onToggle: (value) async {
                    try {
                      await controller.toggleComplete(task.id, value);
                    } catch (e) {
                      debugPrint('Error toggling task completion: $e');
                      rethrow;
                    }
                  },
                  onStartTimer: () => _startTimerForTask(ref, task, context),
                );
              },
            ),
            if (limit != null && tasks.length > limit!) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onViewAll,
                  child: Text(
                    'View all',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Failed to load tasks: $e'),
    );
  }

  // Start timer for a specific task
  void _startTimerForTask(WidgetRef ref, Task task, BuildContext context) {
    // Set the task as the selected topic
    final taskTopic = Topic(
      id: 'task_${task.id}',
      name: task.title,
      color: _getPriorityColorInt(task.priority),
    );

    // Set the topic
    ref.read(selectedTopicProvider.notifier).state = taskTopic;

    // Check if user has a timer mode selected
    final timerModeNotifier = ref.read(timerModeSelectionProvider.notifier);

    if (timerModeNotifier.canStartTimer) {
      // Start timer using the last selected mode
      timerModeNotifier.startSelectedTimer(ref);
    } else {
      // Fallback to 25-minute session if no mode selected
      final timerController = ref.read(timerControllerProvider.notifier);
      timerController.start(const Duration(minutes: 25));
    }

    // Navigate to home screen to show the timer
    context.go('/');
  }

  int _getPriorityColorInt(String priority) {
    switch (priority) {
      case 'high':
        return 0xFFFF5722; // Red
      case 'med':
        return 0xFFFF9800; // Orange
      default:
        return 0xFF4CAF50; // Green
    }
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onToggle,
    required this.onStartTimer,
  });

  final Task task;
  final Future<void> Function(bool) onToggle;
  final VoidCallback onStartTimer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Semantics(
              label: task.completed
                  ? '${task.title} completed'
                  : '${task.title} not completed',
              hint:
                  'Double tap to ${task.completed ? "uncomplete" : "complete"} this task',
              child: Checkbox(
                value: task.completed,
                onChanged: (v) async {
                  try {
                    await onToggle(v ?? false);
                  } catch (e) {
                    debugPrint('Error toggling task completion: $e');
                    // Optionally show a snackbar to the user
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update task: $e'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      decoration: task.completed
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      fontWeight: FontWeight.w600,
                      fontSize: 14, // Smaller font to prevent overflow
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  if ((task.note ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.note!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10, // Smaller font to prevent overflow
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action buttons
            if (!task.completed) ...[
              Semantics(
                label: 'Start timer for ${task.title}',
                hint: 'Double tap to start a focus session for this task',
                button: true,
                child: IconButton(
                  onPressed: onStartTimer,
                  icon: const Icon(Icons.play_arrow),
                  tooltip: 'Start timer for this task',
                  iconSize: 20,
                ),
              ),
            ],
            Semantics(
              label: 'Priority: ${task.priority}',
              child: _PriorityDot(priority: task.priority),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});
  final String priority;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    switch (priority) {
      case 'high':
        color = theme.colorScheme.error;
        break;
      case 'med':
        color = theme.colorScheme.tertiary;
        break;
      default:
        color = theme.colorScheme.primary;
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({this.onViewAll});
  final VoidCallback? onViewAll;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('No tasks yet', style: theme.textTheme.bodyMedium),
            if (onViewAll != null)
              TextButton(onPressed: onViewAll, child: const Text('Add Task')),
          ],
        ),
      ),
    );
  }
}
