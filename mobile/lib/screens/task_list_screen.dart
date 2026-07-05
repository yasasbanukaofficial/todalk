import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/task_card.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final tasks = provider.tasks;
    final currentFilter = provider.filter;

    final filters = ['All', 'Today', 'Upcoming', 'Done'];
    final filterColors = {
      'All': AppColors.lightGrey,
      'Today': AppColors.mint,
      'Upcoming': AppColors.lightBlue,
      'Done': AppColors.lavender,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'Tasks',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filters.map((f) {
                    final isSelected = currentFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => provider.setFilter(f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? filterColors[f]!
                                : AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(
                              AppTheme.chipRadius,
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? filterColors[f]!
                                  : AppColors.lightGrey.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.black
                                  : AppColors.grey,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 300));
                },
                child: tasks.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 80),
                          Center(
                            child: Text(
                              'No tasks found',
                              style: TextStyle(color: AppColors.grey),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          top: 8,
                          bottom: 80,
                        ),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return TaskCard(
                            task: task,
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                '/task-detail',
                                arguments: task.id,
                              );
                            },
                            onToggleDone: () {
                              provider.toggleDone(task.id);
                            },
                            onDelete: () {
                              provider.deleteTask(task.id);
                            },
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
