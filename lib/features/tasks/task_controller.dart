import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'task_repository.dart';
import 'task_model.dart';
import '../achievements/achievement_tracking_service.dart';

// Repository provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

// Task filters state
class TaskFilters {
  final String? priorityFilter;
  final String? tagFilter;
  final bool showCompleted;

  const TaskFilters({
    this.priorityFilter,
    this.tagFilter,
    this.showCompleted = false,
  });

  TaskFilters copyWith({
    String? priorityFilter,
    String? tagFilter,
    bool? showCompleted,
    bool clearPriorityFilter = false,
    bool clearTagFilter = false,
  }) {
    return TaskFilters(
      priorityFilter: clearPriorityFilter
          ? null
          : (priorityFilter ?? this.priorityFilter),
      tagFilter: clearTagFilter ? null : (tagFilter ?? this.tagFilter),
      showCompleted: showCompleted ?? this.showCompleted,
    );
  }
}

// Filters provider
final taskFiltersProvider = StateProvider<TaskFilters>((ref) {
  return const TaskFilters();
});

// Task list controller
class TaskListController extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    try {
      final repository = ref.read(taskRepositoryProvider);
      final filters = ref.watch(taskFiltersProvider);

      debugPrint('TaskListController: Building with filters: $filters');

      // Watch tasks with current filters
      listenSelf((previous, next) {
        debugPrint('TaskListController: State changed from $previous to $next');
      });

      final tasks = await repository
          .watchTasks(
            completed: filters.showCompleted ? null : false,
            priority: filters.priorityFilter,
            tag: filters.tagFilter,
          )
          .first;

      debugPrint('TaskListController: Loaded ${tasks.length} tasks');
      return tasks;
    } catch (e) {
      debugPrint('TaskListController: Error in build(): $e');
      rethrow;
    }
  }

  // Watch tasks stream with current filters
  Stream<List<Task>> watchTasks() {
    final repository = ref.read(taskRepositoryProvider);
    final filters = ref.watch(taskFiltersProvider);

    return repository.watchTasks(
      completed: filters.showCompleted ? null : false,
      priority: filters.priorityFilter,
      tag: filters.tagFilter,
    );
  }

  // Add a new task
  Future<void> addTask(Task task) async {
    final repository = ref.read(taskRepositoryProvider);

    try {
      await repository.add(task);

      // Track task planning for achievements
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final trackingService = AchievementTrackingService();
        await trackingService.trackTaskPlanning(
          uid: currentUser.uid,
          date: DateTime.now(),
          tasksAdded: 1,
        );
      }

      // Refresh the state
      ref.invalidateSelf();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  // Update an existing task
  Future<void> updateTask(Task task) async {
    final repository = ref.read(taskRepositoryProvider);

    try {
      await repository.update(task);
      // Refresh the state
      ref.invalidateSelf();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  // Toggle task completion
  Future<void> toggleComplete(String taskId, bool value) async {
    final repository = ref.read(taskRepositoryProvider);

    try {
      await repository.toggleComplete(taskId, value);
      // Refresh the state
      ref.invalidateSelf();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    final repository = ref.read(taskRepositoryProvider);

    try {
      await repository.delete(taskId);
      // Refresh the state
      ref.invalidateSelf();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  // Update filters
  void updateFilters(TaskFilters filters) {
    ref.read(taskFiltersProvider.notifier).state = filters;
    // Invalidate to reload with new filters
    ref.invalidateSelf();
  }

  // Clear filters
  void clearFilters() {
    ref.read(taskFiltersProvider.notifier).state = const TaskFilters();
    ref.invalidateSelf();
  }
}

// Task list controller provider
final taskListControllerProvider =
    AsyncNotifierProvider<TaskListController, List<Task>>(() {
      return TaskListController();
    });

// Convenience providers for filtered tasks
final filteredTasksProvider = StreamProvider<List<Task>>((ref) {
  try {
    // Watch filters to rebuild stream when filters change
    final filters = ref.watch(taskFiltersProvider);
    final repository = ref.read(taskRepositoryProvider);

    debugPrint('filteredTasksProvider: Watching tasks with filters: $filters');

    // Return stream that reacts to filter changes
    return repository.watchTasks(
      completed: filters.showCompleted ? null : false,
      priority: filters.priorityFilter,
      tag: filters.tagFilter,
    );
  } catch (e) {
    debugPrint('filteredTasksProvider: Error: $e');
    return Stream.value([]);
  }
});
