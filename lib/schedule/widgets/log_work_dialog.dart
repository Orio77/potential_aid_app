import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/providers/task_search_notifier.dart';
import 'package:potential_aid_app/schedule/providers/schedule_notifier.dart';
import 'package:potential_aid_app/schedule/services/add_block_service.dart';
import 'package:potential_aid_app/widgets/util/search_text_field.dart';

class LogWorkDialog extends ConsumerStatefulWidget {
  const LogWorkDialog({super.key});

  @override
  ConsumerState<LogWorkDialog> createState() => _LogWorkDialogState();
}

class _LogWorkDialogState extends ConsumerState<LogWorkDialog> {
  TaskData? _selectedTask;
  ProjectData? _selectedProject;
  bool _isLoading = false;
  bool _autoFocusEnabled = true;

  final _hoursController = TextEditingController(text: '1');
  final _minutesController = TextEditingController(text: '0');
  final _unitsController = TextEditingController(text: '1');

  final _taskFocusNode = FocusNode();
  final _hoursFocusNode = FocusNode();
  final _minutesFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _taskFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _unitsController.dispose();
    _taskFocusNode.dispose();
    _hoursFocusNode.dispose();
    _minutesFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onTaskSelected(TaskData task) async {
    final project = await ref
        .read(databaseProvider)
        .projectDao
        .getProjectById(task.projectId);
    if (mounted) {
      setState(() {
        _selectedTask = task;
        _selectedProject = project;
      });
      if (_autoFocusEnabled) {
        _hoursFocusNode.requestFocus();
      }
    }
  }

  int get _totalMinutes {
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final mins = int.tryParse(_minutesController.text) ?? 0;
    return hours * 60 + mins;
  }

  bool get _showUnits {
    final taskUnit = _selectedTask?.unit;
    final projectUnit = _selectedProject?.unit;
    if (taskUnit == null || taskUnit.isEmpty) return false;
    if (projectUnit == null || projectUnit.isEmpty) return false;
    return taskUnit == projectUnit;
  }

  bool get _canSubmit =>
      _selectedTask != null && _totalMinutes > 0 && !_isLoading;

  Future<void> _submit() async {
    final task = _selectedTask;
    if (task == null) return;

    setState(() => _isLoading = true);
    try {
      final nextTime = await AddBlockService.calculateNextAvailableTime(ref);
      final startMin = nextTime.hour * 60 + nextTime.minute;
      final duration = _totalMinutes;

      // 1. Create a block for the past day
      final blockId = await ref
          .read(scheduleNotifierProvider.notifier)
          .addBlock(startMin, duration, task.projectId);

      // 2. Mark it fully completed (logs time to stats)
      await ref
          .read(scheduleNotifierProvider.notifier)
          .addBlockCompletion(blockId, duration);

      // 3. Log task progress (updates project.current when units match)
      if (_showUnits) {
        final units = int.tryParse(_unitsController.text) ?? 1;
        if (units > 0) {
          await ref
              .read(scheduleNotifierProvider.notifier)
              .addTaskCompletion(task.id, units);
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setDuration(int totalMinutes) {
    setState(() {
      _autoFocusEnabled = false;
      _hoursController.text = (totalMinutes ~/ 60).toString();
      _minutesController.text = (totalMinutes % 60).toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.add_task),
          SizedBox(width: 8),
          Text('Log Past Work'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchTextField<TaskData, TaskSearchNotifier>(
              labelText: 'Task',
              focusNode: _taskFocusNode,
              searchProvider: taskSearchProvider,
              getDisplayText: (t) => t.name,
              onItemSelected: _onTaskSelected,
              leadingIcon: (_) => const Icon(Icons.task_alt_outlined, size: 16),
            ),
            if (_selectedProject != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 13,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedProject!.name,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'TIME SPENT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _DurationField(
                  controller: _hoursController,
                  focusNode: _hoursFocusNode,
                  suffix: 'h',
                  onChanged: () => setState(() {}),
                  onSubmitted: (_) => _minutesFocusNode.requestFocus(),
                ),
                const SizedBox(width: 8),
                _DurationField(
                  controller: _minutesController,
                  focusNode: _minutesFocusNode,
                  suffix: 'm',
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 4,
                  children: [
                    for (final m in [30, 60, 90, 120])
                      _QuickChip(
                        label: m < 60 ? '${m}m' : '${m ~/ 60}h',
                        onTap: () => _setDuration(m),
                      ),
                  ],
                ),
              ],
            ),
            if (_showUnits) ...[
              const SizedBox(height: 20),
              Text(
                'PROGRESS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '+',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 8),
                  _DurationField(
                    controller: _unitsController,
                    suffix: _selectedTask?.unit ?? '',
                    width: 90,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _canSubmit ? _submit : null,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check, size: 18),
          label: const Text('Log Work'),
        ),
      ],
    );
  }
}

class _DurationField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String suffix;
  final double width;
  final VoidCallback onChanged;
  final ValueChanged<String>? onSubmitted;

  const _DurationField({
    required this.controller,
    required this.suffix,
    required this.onChanged,
    this.focusNode,
    this.width = 56,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          suffixText: suffix,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
        ),
        onChanged: (_) => onChanged(),
        onSubmitted: onSubmitted,
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

Future<void> showLogWorkDialog(BuildContext context) {
  return showDialog(context: context, builder: (_) => const LogWorkDialog());
}
