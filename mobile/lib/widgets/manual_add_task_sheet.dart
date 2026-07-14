import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'bottom_sheet_container.dart';
import 'chip_selector.dart';
import 'pill_button.dart';

class ManualAddTaskSheet extends StatefulWidget {
  const ManualAddTaskSheet({super.key});

  @override
  State<ManualAddTaskSheet> createState() => _ManualAddTaskSheetState();
}

class _ManualAddTaskSheetState extends State<ManualAddTaskSheet> {
  late TextEditingController _titleController;
  DateTime? _dueDate;
  String _priority = 'Medium';

  final List<String> _priorities = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
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
    if (_titleController.text.trim().isEmpty) return;
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
      source: 'Text',
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
            'ADD TASK',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 4,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            autofocus: true,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'What do you need to do?',
              hintStyle: const TextStyle(color: AppColors.textTertiary),
              filled: false,
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
                isSelected: _dueDate != null,
              ),
              const SizedBox(width: 10),
              ChipSelector(
                label: _priority,
                icon: Icons.flag,
                onTap: _cyclePriority,
                isSelected: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Text(
                      'CANCEL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: PillButton(
                  label: 'SAVE TASK',
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
