import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/tasks_notifier.dart';
import 'package:time_machine/time_machine.dart';

class TasksForDeadlineDialog extends ConsumerStatefulWidget {
  final LocalDate deadlineDate;
  const TasksForDeadlineDialog({super.key, required this.deadlineDate});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _TasksForDeadlineListState();
}

class _TasksForDeadlineListState extends ConsumerState<TasksForDeadlineDialog> {
  final Set<TaskData> _selectedTasks = {};
  int? _selectedProjectId;
  late List<Expression<bool> Function($TaskTable)> _predicates;

  void _updatePredicates() {
    final targetDateTime = widget.deadlineDate.toDateTimeUnspecified();
    _predicates = [
      (t) => t.deadline.equals(targetDateTime),
      (t) => t.isCompleted.equals(false),
      (t) => (_selectedProjectId != null)
          ? t.projectId.equals(_selectedProjectId!)
          : const Constant(true),
    ];
  }

  @override
  void initState() {
    super.initState();
    _updatePredicates();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksNotifierProvider(_predicates));
    return AlertDialog(
      title: Center(child: Text('Tasks for ${widget.deadlineDate.toString()}')),
      content: _buildTaskList(tasks),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: _selectedTasks.isEmpty
              ? null
              : () {
                  Navigator.of(context).pop(_selectedTasks.toList());
                },
          child: const Text('Select'),
        ),
      ],
    );
  }

  Widget _buildTaskList(List<TaskData> tasks) {
    return SizedBox(
      width: double.maxFinite,
      height: 350,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Selected Project: $_selectedProjectId"),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(height: 2),
              shrinkWrap: true,
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.task_alt),
                    title: Text(task.name),
                    onTap: () {
                      setState(() {
                        _selectedProjectId ??= task.projectId;

                        if (_selectedTasks.contains(task)) {
                          _selectedTasks.remove(task);
                          if (_selectedTasks.isEmpty) {
                            _selectedProjectId = null;
                          }
                        } else {
                          _selectedTasks.add(task);
                        }

                        _updatePredicates();
                      });
                    },
                    trailing: _selectedTasks.contains(task)
                        ? Icon(
                            Icons.check_circle,
                            color: Colors.deepPurpleAccent,
                          )
                        : Icon(Icons.radio_button_unchecked),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<List<TaskData>?> showTasksForDeadlineDialog(
  BuildContext context,
  LocalDate deadlineDate,
) async {
  return await showDialog(
    context: context,
    builder: (context) => TasksForDeadlineDialog(deadlineDate: deadlineDate),
  );
}
