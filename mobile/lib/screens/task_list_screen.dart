import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/task_card.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredResult = ref.watch(filteredTasksProvider);
    final tasks = filteredResult.$1;
    final currentFilter = filteredResult.$2;

    final filters = ['All', 'Today', 'Upcoming', 'Done'];

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Text('TASKS', style: TextStyle(fontSize: 12, letterSpacing: 4, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: filters.map((f) {
                  final isSelected = currentFilter == f;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => ref.read(taskProvider.notifier).setFilter(f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isSelected ? AppColors.white : AppColors.hairline, width: 1))),
                        child: Text(f.toUpperCase(), textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w500,
                            color: isSelected ? AppColors.textPrimary : AppColors.textTertiary)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => Future.delayed(const Duration(milliseconds: 300)),
                child: tasks.isEmpty
                    ? ListView(children: const [SizedBox(height: 80), Center(child: Text('NO TASKS FOUND', style: TextStyle(fontSize: 12, letterSpacing: 2, color: AppColors.textTertiary)))])
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return TaskCard(
                            task: task,
                            onTap: () => Navigator.of(context).pushNamed('/task-detail', arguments: task.id),
                            onToggleDone: () => ref.read(taskProvider.notifier).toggleDone(task.id),
                            onDelete: () => ref.read(taskProvider.notifier).deleteTask(task.id),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
