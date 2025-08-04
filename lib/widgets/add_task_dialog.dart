import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/schedule_notifier.dart';
import 'package:potential_aid_app/providers/settings_notifier.dart';
import 'package:potential_aid_app/providers/task_search_notifier.dart';
import 'package:potential_aid_app/widgets/duration_picker_dialog.dart';

class AddTaskDialog extends ConsumerStatefulWidget {
  const AddTaskDialog({super.key});

  @override
  ConsumerState<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends ConsumerState<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _focusNode = FocusNode();
  late TimeOfDay _startTime;
  int _durationMinutes = 60;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();

    final settings = ref.read(settingsNotifierProvider);
    _durationMinutes = settings.defaultTaskLength;

    _startTime = _calculateNextAvailableTime();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    super.dispose();
  }

  TimeOfDay _calculateNextAvailableTime() {
    final settings = ref.read(settingsNotifierProvider);
    final schedule = ref.read(scheduleNotifierProvider);

    if (schedule.isEmpty) {
      final defaultMinutes = settings.defaultStartTime;
      return TimeOfDay(hour: defaultMinutes ~/ 60, minute: defaultMinutes % 60);
    }

    final lastBlock = schedule.last;
    final lastEndMinutes =
        lastBlock.block.startMinuteOfDay + lastBlock.block.lengthMinutes;
    final nextStartMinutes = lastEndMinutes + settings.defaultBreakTime;

    return TimeOfDay(
      hour: nextStartMinutes ~/ 60,
      minute: nextStartMinutes % 60,
    );
  }

  int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  String? _validateTaskName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Task name cannot be empty';
    }

    return null;
  }

  void _selectTask(TaskData task) {
    _taskNameController.text = task.name;
    setState(() {
      _showSuggestions = false;
    });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final taskName = _taskNameController.text.trim();
      final startMinutes = _timeOfDayToMinutes(_startTime);

      int taskId = await ref
          .read(scheduleNotifierProvider.notifier)
          .addTask(taskName);
      await ref
          .read(scheduleNotifierProvider.notifier)
          .addBlock(startMinutes, _durationMinutes, taskId);

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
    final searchResults = ref.watch(taskSearchProvider);

    return AlertDialog(
      title: const Center(child: Text('Add New Task')),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _taskNameController,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  labelText: 'Task name',
                  border: OutlineInputBorder(),
                ),
                validator: _validateTaskName,
                enabled: !_isLoading,
                onChanged: (value) {
                  ref.read(taskSearchProvider.notifier).search(value);
                  setState(() {
                    _showSuggestions =
                        value.isNotEmpty && searchResults.isNotEmpty;
                  });
                },
                onTap: () {
                  if (_taskNameController.text.isNotEmpty &&
                      searchResults.isNotEmpty) {
                    setState(() {
                      _showSuggestions = true;
                    });
                  }
                },
              ),

              if (_showSuggestions && searchResults.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white,
                  ),
                  child: ListView.separated(
                    itemBuilder: (context, index) {
                      final task = searchResults[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          task.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                        leading: const Icon(
                          Icons.task_alt,
                          size: 16,
                          color: Colors.blue,
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.grey,
                        ),
                        onTap: () => _selectTask(task),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemCount: searchResults.length,
                  ),
                ),
              ],

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
                subtitle: Text('$_durationMinutes minutes'),
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
          onPressed: _isLoading ? null : _saveTask,
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
      builder: (context) =>
          DurationPickerDialog(initialDuration: _durationMinutes),
    );

    if (picked != null) {
      setState(() {
        _durationMinutes = picked;
      });
    }
  }
}

Future<void> showAddTaskDialog(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (context) => const AddTaskDialog(),
  );
}
