import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/task_card.dart';
import '../widgets/manual_add_task_sheet.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onOpenRecording;
  final ValueChanged<int>? onNavigateToTab;

  const HomeScreen({
    super.key,
    this.onOpenRecording,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final tasks = context.watch<TaskProvider>().recentTasks;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Hi ${user?.name ?? 'there'},\nhow can I help you today?',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    child: Stack(
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          size: 28,
                          color: AppColors.grey,
                        ),
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  QuickActionCard(
                    label: 'Record',
                    icon: Icons.mic,
                    color: AppColors.mint,
                    onTap: () => onOpenRecording?.call(),
                  ),
                  QuickActionCard(
                    label: 'Add Text',
                    icon: Icons.edit_note,
                    color: AppColors.lightBlue,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const ManualAddTaskSheet(),
                      );
                    },
                  ),
                  QuickActionCard(
                    label: "Today's Tasks",
                    icon: Icons.check_circle_outline,
                    color: AppColors.paleYellow,
                    onTap: () {
                      context.read<TaskProvider>().setFilter('Today');
                      onNavigateToTab?.call(1);
                    },
                  ),
                  QuickActionCard(
                    label: 'All Tasks',
                    icon: Icons.list_alt,
                    color: AppColors.lavender,
                    onTap: () {
                      context.read<TaskProvider>().setFilter('All');
                      onNavigateToTab?.call(1);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  border: Border.all(
                    color: AppColors.lightGrey.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      size: 22,
                      color: AppColors.grey,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ask or search for anything',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onOpenRecording?.call(),
                      child: const Icon(
                        Icons.mic,
                        size: 22,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Recent Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 8),
              ...tasks.map((task) => TaskCard(
                task: task,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    '/task-detail',
                    arguments: task.id,
                  );
                },
                onToggleDone: () {
                  context.read<TaskProvider>().toggleDone(task.id);
                },
                onDelete: () {
                  context.read<TaskProvider>().deleteTask(task.id);
                },
              )),
              if (tasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text(
                      'No tasks yet. Tap the mic to add one!',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
