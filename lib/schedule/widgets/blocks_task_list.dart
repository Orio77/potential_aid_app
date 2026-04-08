import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/tables/block.dart';
import 'package:potential_aid_app/schedule/widgets/block_task_row.dart';

class BlocksTaskList extends ConsumerWidget {
  final BlockWithTasks? block;

  const BlocksTaskList({super.key, required this.block});

  Widget _buildEmptyState() {
    return const SizedBox.shrink();
  }

  Widget _buildTaskView(BuildContext context, BlockWithTasks block) {
    if (block.tasks == null || block.tasks!.isEmpty) {
      return _buildEmptyState();
    }

    final List<TaskData> tasks = block.tasks!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Icon(
                  Icons.checklist_rounded,
                  size: 18,
                  color: cs.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tasks',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${tasks.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),
          for (int i = 0; i < tasks.length; i++) ...[
            if (i > 0) Divider(height: 1, color: cs.outlineVariant),
            BlockTaskRow(task: tasks[i]),
          ],
          const SizedBox(height: 4),
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
