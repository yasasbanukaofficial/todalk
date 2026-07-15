import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import 'api_providers.dart';

class TaskState {
  final List<Task> allTasks;
  final String filter;
  final bool isLoaded;
  final bool isOnline;

  const TaskState({
    this.allTasks = const [],
    this.filter = 'All',
    this.isLoaded = false,
    this.isOnline = true,
  });

  TaskState copyWith({
    List<Task>? allTasks,
    String? filter,
    bool? isLoaded,
    bool? isOnline,
  }) {
    return TaskState(
      allTasks: allTasks ?? this.allTasks,
      filter: filter ?? this.filter,
      isLoaded: isLoaded ?? this.isLoaded,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

final taskProvider = NotifierProvider<TaskNotifier, TaskState>(TaskNotifier.new);

final filteredTasksProvider = Provider<(List<Task>, String)>((ref) {
  final state = ref.watch(taskProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  List<Task> filtered;
  switch (state.filter) {
    case 'Today':
      filtered = state.allTasks.where((t) =>
          t.dueDate != null &&
          DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day)
              .isAtSameMomentAs(today)).toList();
    case 'Upcoming':
      filtered = state.allTasks.where((t) =>
          t.dueDate != null && t.dueDate!.isAfter(today)).toList();
    case 'Done':
      filtered = state.allTasks.where((t) => t.isDone).toList();
    default:
      filtered = state.allTasks;
  }
  return (filtered, state.filter);
});

final recentTasksProvider = Provider<List<Task>>((ref) {
  final allTasks = ref.watch(taskProvider).allTasks;
  final sorted = List<Task>.from(allTasks)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return sorted.take(5).toList();
});

class TaskNotifier extends Notifier<TaskState> {
  @override
  TaskState build() => TaskState();

  ApiService get _api => ref.read(apiServiceProvider);

  Future<void> loadTasks() async {
    try {
      final response = await _api.get('/todos', auth: true);
      final data = response['data'] as List<dynamic>? ?? <dynamic>[];
      state = state.copyWith(
        allTasks: data
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList(),
        isOnline: true,
        isLoaded: true,
      );
    } catch (_) {
      state = state.copyWith(isOnline: false, isLoaded: true);
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('tasks_cached');
      if (cached != null) {
        final list = jsonDecode(cached) as List;
        state = state.copyWith(
          allTasks: list
              .map((e) => Task.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
    }
  }

  Future<void> _cacheTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(state.allTasks.map((t) => t.toJson()).toList());
    await prefs.setString('tasks_cached', data);
  }

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  Future<void> addTask(Task task) async {
    if (state.isOnline) {
      try {
        final response =
            await _api.post('/todos', body: task.toCreateJson(), auth: true);
        final data = response['data'] as Map<String, dynamic>;
        state = state.copyWith(
          allTasks: [...state.allTasks, Task.fromJson(data)],
        );
        await _cacheTasks();
        return;
      } catch (_) {
        state = state.copyWith(isOnline: false);
      }
    }
    state = state.copyWith(allTasks: [...state.allTasks, task]);
    await _cacheTasks();
  }

  Future<void> toggleDone(String id) async {
    final index = state.allTasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final task = state.allTasks[index];
    final updated = task.copyWith(isDone: !task.isDone);
    final newTasks = [...state.allTasks];
    newTasks[index] = updated;
    state = state.copyWith(allTasks: newTasks);

    if (state.isOnline) {
      try {
        await _api.patch('/todos/$id',
            body: {'isCompleted': updated.isDone}, auth: true);
      } catch (_) {
        state = state.copyWith(isOnline: false);
      }
    }
    await _cacheTasks();
  }

  Future<void> deleteTask(String id) async {
    final newTasks = state.allTasks.where((t) => t.id != id).toList();
    state = state.copyWith(allTasks: newTasks);
    await _cacheTasks();

    if (state.isOnline) {
      try {
        await _api.delete('/todos/$id', auth: true);
      } catch (_) {
        state = state.copyWith(isOnline: false);
      }
    }
  }

  Future<void> updateTask(Task updated) async {
    final index = state.allTasks.indexWhere((t) => t.id == updated.id);
    if (index == -1) return;

    final newTasks = [...state.allTasks];
    if (state.isOnline) {
      try {
        final response = await _api.patch('/todos/${updated.id}',
            body: updated.toUpdateJson(), auth: true);
        final data = response['data'] as Map<String, dynamic>;
        newTasks[index] = Task.fromJson(data);
      } catch (_) {
        state = state.copyWith(isOnline: false);
        newTasks[index] = updated;
      }
    } else {
      newTasks[index] = updated;
    }
    state = state.copyWith(allTasks: newTasks);
    await _cacheTasks();
  }
}
