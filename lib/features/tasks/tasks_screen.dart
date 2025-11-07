import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'task_model.dart';
import 'task_controller.dart';
import '../../widgets/error_state.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  Future<void> _showEditTaskDialog(Task task) async {
    final titleController = TextEditingController(text: task.title);
    final noteController = TextEditingController(text: task.note ?? '');
    String priority = task.priority;
    int pomodorosRequired = task.pomodorosRequired;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'med', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                  ],
                  onChanged: (v) => priority = v ?? 'low',
                  decoration: const InputDecoration(labelText: 'Priority'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: pomodorosRequired,
                  items: List.generate(8, (i) => i + 1)
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(
                            '$v pomodoro${v == 1 ? '' : 's'} required',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => pomodorosRequired = (v ?? 1).clamp(1, 999),
                  decoration: const InputDecoration(
                    labelText: 'Pomodoros required',
                    helperText: 'Auto-complete when reached',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final note = noteController.text.trim();
                if (title.isEmpty) return;

                final updated = task.copyWith(
                  title: title,
                  note: note.isEmpty ? null : note,
                  priority: priority,
                  pomodorosRequired: pomodorosRequired,
                );

                await ref
                    .read(taskListControllerProvider.notifier)
                    .updateTask(updated);
                if (context.mounted) Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 56),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    String priority = 'low';
    int pomodorosRequired = 1;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'med', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                  ],
                  onChanged: (v) => priority = v ?? 'low',
                  decoration: const InputDecoration(labelText: 'Priority'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: pomodorosRequired,
                  items: List.generate(8, (i) => i + 1)
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(
                            '$v pomodoro${v == 1 ? '' : 's'} required',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => pomodorosRequired = (v ?? 1).clamp(1, 999),
                  decoration: const InputDecoration(
                    labelText: 'Pomodoros required',
                    helperText: 'Auto-complete when reached',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final note = noteController.text.trim();
                if (title.isEmpty) return;

                final task = Task(
                  id: 'new', // Firestore will assign ID
                  title: title,
                  note: note.isEmpty ? null : note,
                  priority: priority,
                  tags: const [],
                  completed: false,
                  createdAt: DateTime.now(),
                  dueAt: null,
                  pomodorosDone: 0,
                  minutesLogged: 0,
                  pomodorosRequired: pomodorosRequired,
                );

                await ref
                    .read(taskListControllerProvider.notifier)
                    .addTask(task);
                if (context.mounted) Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 56),
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(filteredTasksProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
            tooltip: 'Filter tasks',
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(taskListControllerProvider);
            },
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Dismissible(
                  key: Key(task.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Theme.of(context).colorScheme.error,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Task'),
                            content: Text(
                              'Are you sure you want to delete "${task.title}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (direction) async {
                    try {
                      await ref
                          .read(taskListControllerProvider.notifier)
                          .deleteTask(task.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Task deleted')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error deleting task: ${e.toString()}',
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                        );
                      }
                    }
                  },
                  child: ListTile(
                    leading: Checkbox(
                      value: task.completed,
                      onChanged: (v) => ref
                          .read(taskListControllerProvider.notifier)
                          .toggleComplete(task.id, v ?? false),
                    ),
                    title: Text(task.title),
                    subtitle: task.note != null ? Text(task.note!) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PriorityDot(priority: task.priority),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          tooltip: 'Edit task',
                          onPressed: () => _showEditTaskDialog(task),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorState(
          title: 'Failed to Load Tasks',
          message: ErrorMessageHelper.getUserFriendlyMessage(error),
          details: ErrorMessageHelper.getErrorDetails(error),
          onRetry: () => ref.invalidate(taskListControllerProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    final filters = ref.watch(taskFiltersProvider);
    final hasFilters =
        filters.priorityFilter != null ||
        filters.tagFilter != null ||
        filters.showCompleted;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.filter_list_off : Icons.task_alt,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No tasks match your filters' : 'No tasks yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try adjusting your filters or add a new task'
                : 'Add your first task to get started',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (hasFilters) ...[
            ElevatedButton(
              onPressed: () {
                ref.read(taskFiltersProvider.notifier).state =
                    const TaskFilters();
              },
              child: const Text('Clear Filters'),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterBottomSheet(),
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

class _FilterBottomSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(taskFiltersProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Tasks',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          // Priority filter
          Text('Priority', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  context,
                  'All',
                  filters.priorityFilter == null,
                  () {
                    ref.read(taskFiltersProvider.notifier).state = filters
                        .copyWith(clearPriorityFilter: true);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  context,
                  'Low',
                  filters.priorityFilter == 'low',
                  () {
                    ref.read(taskFiltersProvider.notifier).state = filters
                        .copyWith(priorityFilter: 'low');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  context,
                  'Medium',
                  filters.priorityFilter == 'med',
                  () {
                    ref.read(taskFiltersProvider.notifier).state = filters
                        .copyWith(priorityFilter: 'med');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  context,
                  'High',
                  filters.priorityFilter == 'high',
                  () {
                    ref.read(taskFiltersProvider.notifier).state = filters
                        .copyWith(priorityFilter: 'high');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Show completed toggle
          SwitchListTile(
            title: const Text('Show Completed Tasks'),
            subtitle: const Text('Include completed tasks in the list'),
            value: filters.showCompleted,
            onChanged: (value) {
              ref.read(taskFiltersProvider.notifier).state = filters.copyWith(
                showCompleted: value,
              );
            },
          ),

          const SizedBox(height: 24),

          // Clear filters button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ref.read(taskFiltersProvider.notifier).state =
                    const TaskFilters();
                Navigator.of(context).pop();
              },
              child: const Text('Clear All Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }
}
