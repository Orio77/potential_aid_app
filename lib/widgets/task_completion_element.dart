import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/schedule_notifier.dart';

class TaskCompletionElement extends ConsumerStatefulWidget {
  final TaskData task;
  final Function(int taskId, int completionCount)? onTaskCompletion;

  const TaskCompletionElement({
    super.key,
    required this.task,
    required this.onTaskCompletion,
  });

  @override
  ConsumerState<TaskCompletionElement> createState() =>
      TaskCompletionElementState();
}

class TaskCompletionElementState extends ConsumerState<TaskCompletionElement> {
  final _completionController = TextEditingController();
  late int taskLength;
  late int completionCount;

  @override
  void initState() {
    super.initState();
    taskLength = widget.task.endGoal;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(width: 8),
        const Icon(Icons.task_alt),
        const SizedBox(width: 16),
        ConstrainedBox(
          constraints: BoxConstraints.tightFor(width: _fieldWidth(taskLength)),
          child: TextField(
            controller: _completionController,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(taskLength.toString().length),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(' / $taskLength ${widget.task.unit}'),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () {
            completionCount = taskLength;
            setState(() {
              _completionController.text = completionCount.toString();
            });
          },
          child: Text('>>'),
        ),
      ],
    );
  }

  double _fieldWidth(int max) {
    const double base = 36;
    const double perDigit = 12;
    final int digits = max.toString().length.clamp(2, 3);
    return base + perDigit * digits;
  }

  Future<int?> saveCompletion() async {
    final inputText = _completionController.text.trim();
    final completionCount = int.tryParse(inputText);

    print("Task completion clicked with $completionCount count");

    if (completionCount == null) {
      return null;
    }

    try {
      final res = await ref
          .read(scheduleNotifierProvider.notifier)
          .addTaskCompletion(widget.task.id, completionCount);

      print("Resulting completion id: $res");

      widget.onTaskCompletion?.call(widget.task.id, completionCount);

      return res;
    } catch (e) {
      rethrow;
    }
  }
}
