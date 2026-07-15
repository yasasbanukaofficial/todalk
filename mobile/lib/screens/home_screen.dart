import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/task_card.dart';
import '../widgets/manual_add_task_sheet.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback? onOpenRecording;
  final ValueChanged<int>? onNavigateToTab;

  const HomeScreen({
    super.key,
    this.onOpenRecording,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final allTasks = ref.watch(taskProvider).allTasks;
    final recentTasks = ref.watch(recentTasksProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueToday = allTasks.where((t) =>
        t.dueDate != null &&
        !t.isDone &&
        DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day).isAtSameMomentAs(today)).length;

    final totalActive = allTasks.where((t) => !t.isDone).length;

    return Scaffold(
      backgroundColor: AppColors.black,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TODALK', style: TextStyle(fontSize: 12, letterSpacing: 4, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text('Hi ${user?.name ?? 'there'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(border: Border.all(color: AppColors.hairline, width: 1), shape: BoxShape.circle),
                    child: Center(child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.priorityHigh, shape: BoxShape.circle))),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(border: Border.all(color: AppColors.hairline, width: 1), borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('$totalActive', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300, color: AppColors.textPrimary)),
                      const SizedBox(width: 8),
                      Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(totalActive == 1 ? 'TASK' : 'TASKS', style: const TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w500, color: AppColors.textSecondary))),
                    ]),
                    const SizedBox(height: 4),
                    Text('$dueToday due today', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 20),
                    SizedBox(height: 48, child: CustomPaint(size: const Size(double.infinity, 48), painter: _TrendPainter(tasks: allTasks))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  QuickActionCard(label: 'Record', icon: Icons.mic, onTap: () => onOpenRecording?.call()),
                  const SizedBox(width: 8),
                  QuickActionCard(label: 'Add Text', icon: Icons.edit_note, onTap: () {
                    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const ManualAddTaskSheet());
                  }),
                  const SizedBox(width: 8),
                  QuickActionCard(label: "Today's Tasks", icon: Icons.check_circle_outline, onTap: () {
                    ref.read(taskProvider.notifier).setFilter('Today');
                    onNavigateToTab?.call(1);
                  }),
                  const SizedBox(width: 8),
                  QuickActionCard(label: 'All Tasks', icon: Icons.list_alt, onTap: () {
                    ref.read(taskProvider.notifier).setFilter('All');
                    onNavigateToTab?.call(1);
                  }),
                ]),
              ),
              const SizedBox(height: 28),
              const Text('RECENT', style: TextStyle(fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              ...recentTasks.map((task) => TaskCard(
                task: task,
                onTap: () => Navigator.of(context).pushNamed('/task-detail', arguments: task.id),
                onToggleDone: () => ref.read(taskProvider.notifier).toggleDone(task.id),
                onDelete: () => ref.read(taskProvider.notifier).deleteTask(task.id),
              )),
              if (recentTasks.isEmpty)
                Padding(padding: const EdgeInsets.only(top: 32), child: Center(child: Text('No tasks yet. Tap the mic to add one!', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)))),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<dynamic> tasks;
  _TrendPainter({required this.tasks});

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dotRadius = 3.0;
    final spacing = size.width / 7;
    final midY = size.height / 2;
    final dotPositions = <Offset>[];

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final count = tasks.where((t) {
        final dt = t.dueDate;
        if (dt == null) return false;
        return DateTime(dt.year, dt.month, dt.day).isAtSameMomentAs(day);
      }).length;
      final x = spacing * (6 - i) + spacing / 2;
      final normalized = count > 5 ? 1.0 : count / 5;
      dotPositions.add(Offset(x, midY - (normalized * (size.height / 2 - 8))));
    }

    final linePaint = Paint()..color = AppColors.hairline..strokeWidth = 1..style = PaintingStyle.stroke;
    final linePath = Path();
    for (int i = 0; i < dotPositions.length; i++) {
      if (i == 0) { linePath.moveTo(dotPositions[i].dx, dotPositions[i].dy); }
      else { linePath.lineTo(dotPositions[i].dx, dotPositions[i].dy); }
    }
    canvas.drawPath(linePath, linePaint);

    for (int i = 0; i < dotPositions.length; i++) {
      canvas.drawCircle(dotPositions[i], i == dotPositions.length - 1 ? dotRadius + 1 : dotRadius,
        Paint()..color = i == dotPositions.length - 1 ? AppColors.white : AppColors.textTertiary..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => oldDelegate.tasks.length != tasks.length;
}
