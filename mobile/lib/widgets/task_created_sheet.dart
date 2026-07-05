import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'bottom_sheet_container.dart';
import 'chip_selector.dart';
import 'pill_button.dart';

class TaskCreatedSheet extends StatefulWidget {
  final String transcribedText;

  const TaskCreatedSheet({super.key, required this.transcribedText});

  @override
  State<TaskCreatedSheet> createState() => _TaskCreatedSheetState();
}

class _TaskCreatedSheetState extends State<TaskCreatedSheet> {
  late TextEditingController _titleController;
  DateTime? _dueDate;
  String _priority = 'Medium';

  final List<String> _priorities = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.transcribedText);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
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

  String _formatDate(DateTime dt) {
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _dueDate ?? DateTime.now(),
        ),
      );
      if (time != null && mounted) {
        setState(() {
          _dueDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _cyclePriority() {
    final idx = _priorities.indexOf(_priority);
    setState(() {
      _priority = _priorities[(idx + 1) % _priorities.length];
    });
  }

  void _save() {
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      dueDate: _dueDate,
      priority: _priority,
      source: 'Voice',
      createdAt: DateTime.now(),
    );
    context.read<TaskProvider>().addTask(task);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Task',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
            decoration: InputDecoration(
              hintText: 'Task title',
              hintStyle: TextStyle(color: AppColors.grey.withValues(alpha: 0.5)),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ChipSelector(
                label: _dueDate != null ? _formatDate(_dueDate!) : 'Set date',
                icon: Icons.calendar_today,
                onTap: _pickDate,
                color: AppColors.paleYellow,
              ),
              const SizedBox(width: 10),
              ChipSelector(
                label: _priority,
                icon: Icons.flag,
                onTap: _cyclePriority,
                color: _priorityColor(_priority),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Discard',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: PillButton(
                  label: 'Save Task',
                  onTap: _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
