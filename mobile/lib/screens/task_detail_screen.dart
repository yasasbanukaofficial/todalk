import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/chip_selector.dart';
import '../widgets/pill_button.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;
  bool _isEditing = false;
  late TextEditingController _titleController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final taskId = ModalRoute.of(context)!.settings.arguments as String;
    final provider = context.read<TaskProvider>();
    _task = provider.tasks.firstWhere((t) => t.id == taskId);
    _titleController = TextEditingController(text: _task.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'No due date';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $hour:$min $amPm';
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'High':
        return AppColors.red.withValues(alpha: 0.15);
      case 'Medium':
        return AppColors.lightBlue;
      case 'Low':
        return AppColors.mint;
      default:
        return AppColors.lightGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final task = provider.tasks.firstWhere(
      (t) => t.id == _task.id,
      orElse: () => _task,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Task Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEditing)
              TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.lightGrey.withValues(alpha: 0.3),
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                  contentPadding: const EdgeInsets.all(14),
                ),
              )
            else
              Text(
                task.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: task.isDone ? AppColors.grey : AppColors.white,
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                ChipSelector(
                  label: _formatDate(task.dueDate),
                  icon: Icons.calendar_today,
                  color: AppColors.paleYellow,
                ),
                const SizedBox(width: 10),
                ChipSelector(
                  label: '${task.priority} Priority',
                  icon: Icons.flag,
                  color: _priorityColor(task.priority),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ChipSelector(
              label: task.source,
              icon: task.source == 'Voice' ? Icons.mic : Icons.edit_note,
              color: task.source == 'Voice' ? AppColors.lavender : AppColors.mint,
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No additional notes.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.grey.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              child: Row(
                children: [
                  const Text(
                    'Created',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.grey,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(task.createdAt),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                if (_isEditing) ...[
                  Expanded(
                    child: PillButton(
                      label: 'Save',
                      onTap: () {
                        provider.updateTask(task.copyWith(
                          title: _titleController.text,
                        ));
                        setState(() => _isEditing = false);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PillButton(
                      label: 'Cancel',
                      backgroundColor: AppColors.lightGrey,
                      textColor: AppColors.white,
                      onTap: () => setState(() => _isEditing = false),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: PillButton(
                      label: 'Edit',
                      backgroundColor: AppColors.surfaceCard,
                      textColor: AppColors.white,
                      onTap: () => setState(() => _isEditing = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PillButton(
                      label: task.isDone ? 'Undo' : 'Mark Done',
                      onTap: () {
                        provider.toggleDone(task.id);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  provider.deleteTask(task.id);
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 20),
                label: const Text(
                  'Delete Task',
                  style: TextStyle(
                    color: AppColors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
