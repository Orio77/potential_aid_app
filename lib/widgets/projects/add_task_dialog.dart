import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';
import 'package:potential_aid_app/providers/task_search_notifier.dart';
import 'package:potential_aid_app/widgets/common/goal_progress_input.dart';
import 'package:potential_aid_app/widgets/util/search_text_field.dart';
import 'package:time_machine/time_machine.dart';

class AddTaskDialog extends ConsumerStatefulWidget {
  final int projectId;
  final TaskData? taskData;

  const AddTaskDialog({super.key, required this.projectId, this.taskData});

  @override
  ConsumerState<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends ConsumerState<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _currentController = TextEditingController();
  final _endGoalController = TextEditingController();
  final _unitController = TextEditingController();
  final _focusNode = FocusNode();
  final _progressInputController = GoalProgressInputController();
  late DateTime _deadline;
  late DateTime _currentDate;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    if (widget.taskData != null) {
      _taskNameController.text = widget.taskData!.name;
      _currentController.text = widget.taskData!.current.toString();
      _endGoalController.text = widget.taskData!.endGoal.toString();
      _unitController.text = widget.taskData!.unit!;
      _deadline = widget.taskData!.deadline!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _initializeValues();
      _isInitialized = true;
    }
  }

  void _initializeValues() {
    _currentDate = ref.watch(dateNotifierProvider).toDateTimeUnspecified();
    if (widget.taskData == null) {
      _deadline = _currentDate.add(Duration(days: 7));
    } else {
      _deadline = widget.taskData!.deadline!;
    }
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _currentController.dispose();
    _endGoalController.dispose();
    _unitController.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(
        child: widget.taskData == null
            ? Text('Add New Task')
            : Text('Edit Task'),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SearchTextField<TaskData, TaskSearchNotifier>(
                controller: _taskNameController,
                focusNode: _focusNode,
                labelText: 'Task name',
                validator: _validateTaskName,
                enabled: !_isLoading,
                searchProvider: taskSearchProvider,
                getDisplayText: (task) => task.name,
                onItemSelected: _selectTask,
                leadingIcon: (task) =>
                    const Icon(Icons.task_alt, size: 16, color: Colors.blue),
                trailingIcon: const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey,
                ),
                predicates: [(task) => !task.isCompleted],
                onFieldSubmitted: (_) {
                  _progressInputController.focusFirst();
                },
              ),

              const SizedBox(height: 16),

              GoalProgressInput(
                currentController: _currentController,
                endGoalController: _endGoalController,
                unitController: _unitController,
                controller: _progressInputController,
              ),

              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.calendar_month, size: 30),
                title: Text(
                  'Deadline: ${LocalDate.dateTime(_deadline).toString('dd-MM-yyyy')}',
                  style: TextStyle(fontSize: 20),
                ),
                onTap: _isLoading ? null : () => _pickDeadline(_currentDate),
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

  String? _validateTaskName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Task name cannot be empty';
    }

    return null;
  }

  void _selectTask(TaskData task) {
    _taskNameController.text = task.name;
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
      final current = int.tryParse(_currentController.text.trim());
      final endGoal = int.tryParse(_endGoalController.text.trim());
      final unit = _unitController.text.trim();

      if (widget.taskData == null) {
        await ref
            .read(projectTasksNotifier(widget.projectId).notifier)
            .addTask(
              taskName,
              widget.projectId,
              _deadline,
              unit: unit,
              current: current,
              endGoal: endGoal,
            );
      } else {
        await ref
            .read(projectTasksNotifier(widget.projectId).notifier)
            .updateTask(
              widget.taskData!.id,
              TaskCompanion(
                name: Value(taskName),
                current: Value(current!),
                endGoal: Value(endGoal!),
                unit: Value(unit),
                deadline: Value(_deadline),
              ),
            );
      }

      ref.invalidate(projectTasksNotifier(widget.projectId));

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

  Future<void> _pickDeadline(DateTime today) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: today.add(Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }
}

Future<void> showAddTaskDialog({
  required BuildContext context,
  required int projectId,
  TaskData? taskData,
}) async {
  await showDialog(
    context: context,
    builder: (context) =>
        AddTaskDialog(projectId: projectId, taskData: taskData),
  );
}
