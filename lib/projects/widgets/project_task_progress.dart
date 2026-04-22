import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/projects/providers/task_progress_providers.dart';
import 'package:potential_aid_app/projects/widgets/progress_update_dialog.dart';
import 'package:potential_aid_app/projects/widgets/project_progress_info.dart';
import 'package:potential_aid_app/stats/widgets/progress_bar.dart';
import 'package:potential_aid_app/utils/completion_utils.dart';

/// Shown in the project detail screen header.
///
/// • No tasks yet → falls back to the original [ProjectProgressInfo] bar
///   (uses project.current / project.goal so a brand-new project still looks
///   reasonable).
/// • Has tasks → global bar (average of first-depth task completion %) +
///   one row per task with an inline progress bar and an "update" button.
class ProjectTaskProgress extends ConsumerWidget {
  final ProjectData project;

  const ProjectTaskProgress({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the "with completed" variant so the overall bar reflects finished
    // root tasks — otherwise they're filtered out by the SQL query behind
    // projectTasksNotifier and the average reads 0% for fully-done projects.
    final tasksAsync =
        ref.watch(firstDepthTasksWithCompletedProvider(project.id));

    return tasksAsync.when(
      // While loading, show the existing simple bar so there's no flash
      loading: () => ProjectProgressInfo(project: project),
      error: (e, _) => ProjectProgressInfo(project: project),
      data: (tasks) {
        if (tasks.isEmpty) return ProjectProgressInfo(project: project);
        return _MultiBarProgress(project: project, tasks: tasks);
      },
    );
  }
}

class _MultiBarProgress extends StatefulWidget {
  final ProjectData project;
  final List<TaskData> tasks;

  const _MultiBarProgress({required this.project, required this.tasks});

  @override
  State<_MultiBarProgress> createState() => _MultiBarProgressState();
}

class _MultiBarProgressState extends State<_MultiBarProgress> {
  static const _initialCount = 3;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = widget.tasks;

    // Global average includes ALL tasks (completed count toward 100%).
    // Treat isCompleted tasks as fully done even if `current` wasn't synced to
    // `endGoal` by whichever path marked them complete.
    final avgCompletion = aggregateRootTaskProgress(tasks);
    final globalPct = avgCompletion * 100;
    final globalColor = CompletionUtils.getCompletionColorM3(
      globalPct,
      theme.colorScheme,
    );

    // Only show uncompleted tasks in the header rows — completed ones are
    // visible via the task list's "Show completed" toggle below. The list
    // is already root-only (depth == 0) from the provider.
    final uncompleted = tasks.where((t) => !t.isCompleted).toList();
    final hasMore = uncompleted.length > _initialCount;
    final visible = _showAll
        ? uncompleted
        : uncompleted.take(_initialCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Global bar ──────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Overall',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: globalColor.withValues(alpha: 0.1),
              ),
              child: Text(
                CompletionUtils.getCompletionText(globalPct),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: globalColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ProgressBar(completionValue: avgCompletion),

        // ── Per-task rows (uncompleted only, first 3 by default) ─────────
        if (uncompleted.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...visible.map((task) => _TaskProgressRow(task: task)),
          if (hasMore) ...[
            const SizedBox(height: 2),
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _showAll = !_showAll),
                icon: Icon(
                  _showAll
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 16,
                ),
                label: Text(
                  _showAll
                      ? 'Show less'
                      : '${uncompleted.length - _initialCount} more',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _TaskProgressRow extends StatelessWidget {
  final TaskData task;

  const _TaskProgressRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = taskProgressFraction(task);
    final pct = progress * 100;
    final color = CompletionUtils.getCompletionColorM3(pct, theme.colorScheme);
    final unit = task.unit ?? '';
    final isComplete = task.isCompleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
                    size: 14,
                    color: color,
                  ),
                ),
              Expanded(
                child: Text(
                  task.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    decoration: isComplete ? TextDecoration.lineThrough : null,
                    color: isComplete
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${task.current}/${task.endGoal}${unit.isNotEmpty ? ' $unit' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (!isComplete)
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    icon: Icon(Icons.edit_outlined, size: 15, color: color),
                    onPressed: () => showProgressUpdateDialog(context, task),
                    padding: EdgeInsets.zero,
                    tooltip: 'Update progress',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
