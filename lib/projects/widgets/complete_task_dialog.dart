import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';
import 'package:potential_aid_app/schedule/providers/schedule_notifier.dart';

class CompleteTaskDialog extends ConsumerStatefulWidget {
  final TaskData task;
  const CompleteTaskDialog({super.key, required this.task});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CompleteTaskDialogState();
}

class _CompleteTaskDialogState extends ConsumerState<CompleteTaskDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.text = widget.task.current.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final int maxValue = widget.task.endGoal;

    return AlertDialog(
      content: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _NumericalRangeFormatter(min: 0, max: maxValue),
              ],
              decoration: InputDecoration(
                labelText: widget.task.unit,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Text(" / ${widget.task.endGoal}", style: TextStyle(fontSize: 20)),
          IconButton(
            onPressed: () {
              setState(() {
                _controller.text = widget.task.endGoal.toString();
              });
            },
            icon: Icon(Icons.double_arrow_rounded),
          ),
        ],
      ),
      title: _title(),
      actions: [_cancelButton(context), _saveButton(navigator)],
      actionsAlignment: MainAxisAlignment.spaceBetween,
    );
  }

  Text _title() => Text("Complete '${widget.task.name}' Task");

  TextButton _cancelButton(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text("cancel"),
    );
  }

  TextButton _saveButton(NavigatorState navigator) {
    return TextButton(
      onPressed:
          (_controller.text.isEmpty ||
              int.tryParse(_controller.text)! <= widget.task.current)
          ? null
          : () async {
              await _completeTask(widget.task, int.tryParse(_controller.text)!);
              navigator.pop();
            },
      child: Text("save"),
    );
  }

  Future<void> _completeTask(TaskData task, int count) async {
    await ref
        .read(scheduleNotifierProvider.notifier)
        .addTaskCompletion(task.id, count - task.current);
    ref.invalidate(projectTasksNotifier(task.projectId));
  }
}

class _NumericalRangeFormatter extends TextInputFormatter {
  final int min;
  final int max;

  _NumericalRangeFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final int? value = int.tryParse(newValue.text);
    if (value == null) {
      return oldValue;
    }

    if (value < min || value > max) {
      return oldValue;
    }

    return newValue;
  }
}

Future<void> showCompleteTaskDialog(BuildContext context, TaskData task) async {
  await showDialog(
    context: context,
    builder: (context) => CompleteTaskDialog(task: task),
  );
}
