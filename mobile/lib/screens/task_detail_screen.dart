import 'dart:math';
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

  Duration? _timeUntilDue(DateTime? dt) {
    if (dt == null) return null;
    return dt.difference(DateTime.now());
  }

  double _urgencyFraction(DateTime? dt) {
    if (dt == null) return 0;
    final diff = dt.difference(DateTime.now());
    final total = const Duration(days: 7);
    final remaining = diff.inMilliseconds / total.inMilliseconds;
    return remaining.clamp(0.0, 1.0);
  }

  String _timeLabel(Duration? d) {
    if (d == null) return 'NO DUE DATE';
    if (d.isNegative) return 'OVERDUE';
    if (d.inDays > 0) return '${d.inDays} DAYS LEFT';
    if (d.inHours > 0) return '${d.inHours} HOURS LEFT';
    return '${d.inMinutes} MIN LEFT';
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

  Color _priorityDotColor(String p) {
    switch (p) {
      case 'High':
        return AppColors.priorityHigh;
      case 'Medium':
        return AppColors.priorityMedium;
      case 'Low':
        return AppColors.priorityLow;
      default:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final task = provider.tasks.firstWhere(
      (t) => t.id == _task.id,
      orElse: () => _task,
    );

    final due = _timeUntilDue(task.dueDate);
    final fraction = _urgencyFraction(task.dueDate);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.hairline, width: 1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _priorityDotColor(task.priority),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Center(
                child: SizedBox(
                  width: 160,
                  height: 160,
                  child: CustomPaint(
                    painter: _UrgencyRingPainter(
                      fraction: fraction,
                      isOverdue: due?.isNegative ?? false,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            task.dueDate != null
                                ? '${due?.inDays ?? 0}'
                                : '--',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w300,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _timeLabel(due),
                            style: const TextStyle(
                              fontSize: 11,
                              letterSpacing: 2,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (_isEditing)
                TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.hairline, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.hairline, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.white, width: 1),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                )
              else
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: task.isDone ? AppColors.textTertiary : AppColors.textPrimary,
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.textTertiary,
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ChipSelector(
                    label: _formatDate(task.dueDate),
                    icon: Icons.calendar_today,
                  ),
                  const SizedBox(width: 10),
                  ChipSelector(
                    label: task.priority,
                    isSelected: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ChipSelector(
                label: task.source,
                icon: task.source == 'Voice' ? Icons.mic : Icons.edit_note,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.hairline, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NOTES',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No additional notes.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textTertiary,
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
                  border: Border.all(color: AppColors.hairline, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      'CREATED',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(task.createdAt),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
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
                        label: 'SAVE',
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
                        label: 'CANCEL',
                        isOutlined: true,
                        onTap: () => setState(() => _isEditing = false),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: PillButton(
                        label: 'EDIT',
                        isOutlined: true,
                        onTap: () => setState(() => _isEditing = true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PillButton(
                        label: task.isDone ? 'UNDO' : 'MARK DONE',
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
                child: GestureDetector(
                  onTap: () {
                    provider.deleteTask(task.id);
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'DELETE TASK',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 2,
                        color: AppColors.priorityHigh,
                      ),
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

class _UrgencyRingPainter extends CustomPainter {
  final double fraction;
  final bool isOverdue;

  _UrgencyRingPainter({required this.fraction, required this.isOverdue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final bgPaint = Paint()
      ..color = AppColors.hairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, bgPaint);

    if (fraction > 0) {
      final progressPaint = Paint()
        ..color = isOverdue ? AppColors.priorityHigh : AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * fraction,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _UrgencyRingPainter old) =>
      old.fraction != fraction || old.isOverdue != isOverdue;
}
