import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  final ApiService _api;
  List<Task> _tasks = [];
  String _filter = 'All';
  bool _isLoaded = false;
  bool _isOnline = true;

  TaskProvider({required ApiService apiService}) : _api = apiService;

  List<Task> get tasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_filter) {
      case 'Today':
        return _tasks.where((t) =>
            t.dueDate != null &&
            DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day)
                .isAtSameMomentAs(today)).toList();
      case 'Upcoming':
        return _tasks.where((t) =>
            t.dueDate != null && t.dueDate!.isAfter(today)).toList();
      case 'Done':
        return _tasks.where((t) => t.isDone).toList();
      default:
        return _tasks;
    }
  }

  List<Task> get recentTasks {
    final sorted = List<Task>.from(_tasks)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(5).toList();
  }

  String get filter => _filter;
  bool get isLoaded => _isLoaded;
  bool get isOnline => _isOnline;

  Future<void> loadTasks() async {
    try {
      final response = await _api.get('/todos', auth: true);
      final data = response['data'] as List<dynamic>? ?? <dynamic>[];
      _tasks = data
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
      _isOnline = true;
    } catch (_) {
      _isOnline = false;
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('tasks_cached');
      if (cached != null) {
        final list = jsonDecode(cached) as List;
        _tasks = list
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _cacheTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString('tasks_cached', data);
  }

  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    if (_isOnline) {
      try {
        final response =
            await _api.post('/todos', body: task.toCreateJson(), auth: true);
        final data = response['data'] as Map<String, dynamic>;
        _tasks.add(Task.fromJson(data));
        notifyListeners();
        await _cacheTasks();
        return;
      } catch (_) {
        _isOnline = false;
      }
    }
    _tasks.add(task);
    notifyListeners();
    await _cacheTasks();
  }

  Future<void> toggleDone(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final updated = _tasks[index].copyWith(isDone: !_tasks[index].isDone);
    if (_isOnline) {
      try {
        await _api.patch('/todos/$id',
            body: {'isCompleted': updated.isDone}, auth: true);
        _tasks[index] = updated;
      } catch (_) {
        _isOnline = false;
        _tasks[index] = updated;
      }
    } else {
      _tasks[index] = updated;
    }
    notifyListeners();
    await _cacheTasks();
  }

  Future<void> deleteTask(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    _tasks.removeAt(index);
    notifyListeners();
    await _cacheTasks();

    if (_isOnline) {
      try {
        await _api.delete('/todos/$id', auth: true);
      } catch (_) {
        _isOnline = false;
      }
    }
  }

  Future<void> updateTask(Task updated) async {
    final index = _tasks.indexWhere((t) => t.id == updated.id);
    if (index == -1) return;

    if (_isOnline) {
      try {
        final response = await _api.patch('/todos/${updated.id}',
            body: updated.toUpdateJson(), auth: true);
        final data = response['data'] as Map<String, dynamic>;
        _tasks[index] = Task.fromJson(data);
      } catch (_) {
        _isOnline = false;
        _tasks[index] = updated;
      }
    } else {
      _tasks[index] = updated;
    }
    notifyListeners();
    await _cacheTasks();
  }
}
