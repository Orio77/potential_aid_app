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
    final progress = task.endGoal > 0 ? task.current / task.endGoal : 0.0;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: onTap,
        title: Text(
          task.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 4),
            Text('${task.current}/${task.endGoal} ${task.unit}'),
            Text(
              'Deadline: ${task.deadline != null ? LocalDate.dateTime(task.deadline!).toString('dd-MM-yyyy') : 'No deadline set'}',
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle_outline),
          onPressed: onComplete,
        ),
      ),
    );
  }
}
