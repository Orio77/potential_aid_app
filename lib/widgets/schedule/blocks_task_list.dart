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
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: tasks
              .map(
                (task) => task.isCompleted
                    ? _buildTaskCompletedState(task)
                    : _buildDefaultTaskState(task, theme),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTaskCompletedState(TaskData task) {
    return Text('completed');
  }

  Widget _buildDefaultTaskState(TaskData task, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fiber_manual_record,
            size: 10.0,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            task.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),

            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
