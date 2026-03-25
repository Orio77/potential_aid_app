import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/tables/block.dart';

class BlocksTaskList extends ConsumerWidget {
  final BlockWithTasks? block;

  const BlocksTaskList({super.key, required this.block});

  Widget _buildEmptyState() {
    return SizedBox.shrink();
  }

  Widget _buildTaskView(BuildContext context, BlockWithTasks block) {
    if (block.tasks == null || block.tasks!.isEmpty) {
      return _buildEmptyState();
    }

    final List<TaskData> tasks = block.tasks!;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: tasks.map((task) => _buildTaskState(task)).toList(),
        ),
      ),
    );
  }

  Widget _buildTaskState(TaskData task) {
    final completedStyle = TextStyle(
      decoration: TextDecoration.lineThrough,
      fontStyle: FontStyle.italic,
    );
    final defaultStyle = TextStyle();

    return Text(
      task.name,
      style: task.isCompleted ? completedStyle : defaultStyle,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (block) {
      null => _buildEmptyState(),
      _ => _buildTaskView(context, block!),
    };
  }
}
