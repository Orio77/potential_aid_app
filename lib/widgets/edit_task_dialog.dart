import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/schedule_notifier.dart';
import 'package:potential_aid_app/widgets/duration_picker_dialog.dart';

class EditTaskDialog extends ConsumerStatefulWidget {
  final int blockId;
  final int taskId;
  final String initialTaskName;
  final int initialStartTime;
  final int initialDuration;

  const EditTaskDialog({
    super.key,
    required this.blockId,
    required this.taskId,
    required this.initialTaskName,
    required this.initialStartTime,
    required this.initialDuration,
  });

  @override
  ConsumerState<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends ConsumerState<EditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  late int _duration;
  late TimeOfDay _startTime;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    _duration = widget.initialDuration;
    _startTime = _minutesToTimeOfDay(widget.initialStartTime);
    _taskNameController.text = widget.initialTaskName;
    super.initState();
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    super.dispose();
  }

  String? _validateTaskName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Task name cannot be empty';
    }

    return null;
  }

  TimeOfDay _minutesToTimeOfDay(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  Future<void> _editTask(int blockId, int taskId) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final taskName = _taskNameController.text.trim();

      await ref
          .read(scheduleNotifierProvider.notifier)
          .editTask(taskId, taskName);
      await ref
          .read(scheduleNotifierProvider.notifier)
          .editBlock(blockId, _timeOfDayToMinutes(_startTime), _duration, null);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save task: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Center(child: Text('Edit Task')),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _taskNameController,
                decoration: const InputDecoration(
                  labelText: 'Task name',
                  border: OutlineInputBorder(),
                ),
                validator: _validateTaskName,
                enabled: !_isLoading,
              ),

              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Start Time'),
                subtitle: Text(_startTime.format(context)),
                onTap: _isLoading ? null : _pickStartTime,
              ),

              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Duration'),
                subtitle: Text('$_duration minutes'),
                onTap: _isLoading ? null : _pickDuration,
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : (() => _editTask(widget.blockId, widget.taskId)),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _pickStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _pickDuration() async {
    final int? picked = await showDialog(
      context: context,
      builder: (context) => DurationPickerDialog(initialDuration: _duration),
    );

    if (picked != null) {
      setState(() {
        _duration = picked;
      });
    }
  }
}

Future<void> showEditTaskDialog(
  BuildContext context, {
  required int blockId,
  required int taskId,
  required String initialTaskName,
  required int initialStartTime,
  required int initialDuration,
}) async {
  await showDialog(
    context: context,
    builder: (context) => EditTaskDialog(
      blockId: blockId,
      taskId: taskId,
      initialTaskName: initialTaskName,
      initialStartTime: initialStartTime,
      initialDuration: initialDuration,
    ),
  );
}
