import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/projects/widgets/progress_update_dialog.dart';
import 'package:potential_aid_app/projects/providers/task_progress_providers.dart';
import 'package:potential_aid_app/utils/completion_utils.dart';

class SubtaskProgressSection extends ConsumerWidget {
  final TaskData task;

  const SubtaskProgressSection({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtasksAsync = ref.watch(taskSubtasksProvider(task.id));

    return subtasksAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (subtasks) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 8),
              if (subtasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'No subtasks',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...subtasks.map((s) => _SubtaskProgressRow(subtask: s)),
            ],
          ),
        );
      },
    );
  }
}

class _SubtaskProgressRow extends StatelessWidget {
  final TaskData subtask;

  const _SubtaskProgressRow({required this.subtask});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = subtask.endGoal > 0
        ? (subtask.current / subtask.endGoal).clamp(0.0, 1.0)
        : 0.0;
    final pct = progress * 100;
    final color = CompletionUtils.getCompletionColorM3(pct, theme.colorScheme);
    final unit = subtask.unit ?? '';
    final isComplete = subtask.isCompleted;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isComplete)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 12,
                    color: color,
                  ),
                ),
              Expanded(
                child: Text(
                  subtask.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    decoration: isComplete ? TextDecoration.lineThrough : null,
                    color: isComplete
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${subtask.current}/${subtask.endGoal}${unit.isNotEmpty ? ' $unit' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              if (!isComplete)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    icon: Icon(Icons.edit_outlined, size: 13, color: color),
                    onPressed: () =>
                        showProgressUpdateDialog(context, subtask),
                    padding: EdgeInsets.zero,
                    tooltip: 'Update progress',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
