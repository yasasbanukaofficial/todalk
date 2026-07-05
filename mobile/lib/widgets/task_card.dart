import 'package:flutter/material.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggleDone;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleDone,
    this.onDelete,
  });

  Color _accentColor() {
    switch (task.priority) {
      case 'High':
        return AppColors.red;
      case 'Medium':
        return AppColors.lightBlue;
      case 'Low':
        return AppColors.mint;
      default:
        return AppColors.grey;
    }
  }

  Color _sourceIconBg() {
    return task.source == 'Voice' ? AppColors.lavender.withValues(alpha: 0.2) : AppColors.paleYellow.withValues(alpha: 0.2);
  }

  Color _sourceIconColor() {
    return task.source == 'Voice' ? AppColors.lavender : AppColors.paleYellow;
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = date.difference(today).inDays;

    String day;
    if (diff == 0) {
      day = 'Today';
    } else if (diff == 1) {
      day = 'Tomorrow';
    } else {
      day = '${dt.month}/${dt.day}';
    }

    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day, $hour:$min $amPm';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          onDelete?.call();
          return false;
        }
        onToggleDone?.call();
        return false;
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: AppColors.lightGrey.withValues(alpha: 0.2),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: _accentColor(),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.cardRadius),
                      bottomLeft: Radius.circular(AppTheme.cardRadius),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: onToggleDone,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: task.isDone
                                    ? AppColors.mint
                                    : AppColors.grey,
                                width: 2,
                              ),
                              color: task.isDone
                                  ? AppColors.mint
                                  : Colors.transparent,
                            ),
                            child: task.isDone
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: AppColors.black,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: task.isDone
                                      ? AppColors.grey
                                      : AppColors.white,
                                  decoration: task.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: AppColors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (task.dueDate != null)
                                Text(
                                  _formatDate(task.dueDate),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _sourceIconBg(),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            task.source == 'Voice'
                                ? Icons.mic
                                : Icons.edit_note,
                            size: 16,
                            color: _sourceIconColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
