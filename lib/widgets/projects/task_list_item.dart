import 'package:flutter/material.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:time_machine/time_machine.dart';

class TaskListItem extends StatelessWidget {
  final TaskData task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  const TaskListItem({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text(
            'Title: ${task.name}',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Text('${task.current}/${task.endGoal} ${task.unit}'),
          Text(
            'Deadline: ${task.deadline != null ? LocalDate.dateTime(task.deadline!).toString('dd-MM-yyyy') : 'No deadline set'}',
          ),
        ],
      ),
    );
  }
}
