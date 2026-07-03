import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  String _filter = 'All';
  bool _isLoaded = false;

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

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('tasks');
    if (data != null) {
      final list = jsonDecode(data) as List;
      _tasks = list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    // TODO: replace with real API call
    await prefs.setString('tasks', data);
  }

  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    _tasks.add(task);
    notifyListeners();
    await _saveTasks();
  }

  Future<void> toggleDone(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(isDone: !_tasks[index].isDone);
      notifyListeners();
      await _saveTasks();
    }
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    await _saveTasks();
  }

  Future<void> updateTask(Task updated) async {
    final index = _tasks.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _tasks[index] = updated;
      notifyListeners();
      await _saveTasks();
    }
  }
}
