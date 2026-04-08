import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/tables/block.dart';
import 'package:potential_aid_app/schedule/providers/block_with_tasks_notifier.dart';
import 'package:potential_aid_app/schedule/providers/completion_notifier.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:potential_aid_app/utils/completion_utils.dart';

/// Read-only summary dialog for a block that is in the past or completed.
/// Shows project info, time range, and per-task progress.
class BlockInfoDialog extends ConsumerWidget {
  final int blockId;

  const BlockInfoDialog({super.key, required this.blockId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockAsync = ref.watch(blockTasksNotifier(blockId));
    final completionAsync = ref.watch(blockCompletionPercentageProvider(blockId));

    return blockAsync.when(
      data: (blockWithTasks) {
        final projectAsync = ref.watch(
          projectProvider(blockWithTasks.block.projectId),
        );
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          title: projectAsync.when(
            data: (project) => _DialogTitle(
              projectName: project?.name ?? 'Deleted Project',
              completionPercentage: completionAsync.valueOrNull,
            ),
            loading: () => const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, _) => const Text('Block Info'),
          ),
          content: _DialogContent(blockWithTasks: blockWithTasks),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
      loading: () => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        title: const Text('Block Info'),
        content: const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
      error: (error, _) => AlertDialog(
        title: const Text('Block Info'),
        content: Text('Error loading block: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DialogTitle extends StatelessWidget {
  final String projectName;
  final double? completionPercentage;

  const _DialogTitle({required this.projectName, this.completionPercentage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            projectName,
            style: theme.textTheme.titleLarge,
          ),
        ),
        if (completionPercentage != null) ...[
          const SizedBox(width: 8),
          _CompletionBadge(percentage: completionPercentage!),
        ],
      ],
    );
  }
}

class _CompletionBadge extends StatelessWidget {
  final double percentage;

  const _CompletionBadge({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final color = CompletionUtils.getCompletionColor(percentage);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${percentage.toInt()}%',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DialogContent extends StatelessWidget {
  final BlockWithTasks blockWithTasks;

  const _DialogContent({required this.blockWithTasks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = blockWithTasks.tasks ?? [];

    return SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TimeRow(blockWithTasks: blockWithTasks, theme: theme),
          if (tasks.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              'Tasks',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: tasks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, i) => _TaskRow(task: tasks[i], theme: theme),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final BlockWithTasks blockWithTasks;
  final ThemeData theme;

  const _TimeRow({required this.blockWithTasks, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.access_time, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          blockWithTasks.formatTimeRange(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            blockWithTasks.formatDuration(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  final TaskData task;
  final ThemeData theme;

  const _TaskRow({required this.task, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.isCompleted;
    final hasProgress = task.endGoal > 0;
    final progressText = hasProgress
        ? '${task.current} / ${task.endGoal}${task.unit?.isNotEmpty == true ? ' ${task.unit}' : ''}'
        : null;

    return Row(
      children: [
        Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: isCompleted
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            task.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
        if (progressText != null) ...[
          const SizedBox(width: 8),
          Text(
            progressText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

Future<void> showBlockInfoDialog(BuildContext context, int blockId) {
  return showDialog(
    context: context,
    builder: (_) => BlockInfoDialog(blockId: blockId),
  );
}
