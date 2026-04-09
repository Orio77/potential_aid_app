import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/breakdown/screens/task_breakdown_screen.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/pursuit/models/pursuit_focus_state.dart';
import 'package:potential_aid_app/pursuit/providers/pursuit_focus_notifier.dart';
import 'package:potential_aid_app/pursuit/widgets/pursuit_colors.dart';
import 'package:potential_aid_app/pursuit/widgets/pursuit_slots_bar.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';
/// Task-map view: a unified, cross-project, reversed task list with swimlane
/// colour coding and completion/navigation actions.
class PursuitTaskMapBody extends ConsumerWidget {
  const PursuitTaskMapBody({
    super.key,
    required this.pursuit,
    required this.projects,
  });

  final PursuitFocusState pursuit;
  final List<ProjectData> projects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Build task → project lookup from the validated task queues.
    final taskToProject = <int, int>{};
    for (final e in pursuit.taskQueues.entries) {
      for (final tid in e.value) {
        taskToProject[tid] = e.key;
      }
    }

    // Only show tasks whose project is still active/visible.
    final uto = pursuit.unifiedTaskOrder
        .where((tid) => taskToProject.containsKey(tid))
        .toList();

    return Column(
      children: [
        Expanded(
          child: uto.isEmpty
              ? _EmptyTaskPlaceholder(theme: theme)
              : ReorderableListView.builder(
                  // index 0 at bottom = most immediate task.
                  // Dragging UP pushes a task further into the future.
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 64, 16, 8),
                  onReorder: (oldIdx, newIdx) => ref
                      .read(pursuitFocusNotifierProvider.notifier)
                      .reorderUnifiedTasks(oldIdx, newIdx),
                  itemCount: uto.length,
                  itemBuilder: (ctx, index) {
                    final tid = uto[index];
                    final pid = taskToProject[tid];
                    final color = pid != null
                        ? projectColor(pid, projects, pursuit.slots)
                        : theme.colorScheme.outline;

                    return PursuitUnifiedTaskCard(
                      key: ValueKey('utask_$tid'),
                      taskId: tid,
                      projectId: pid,
                      position: index + 1,
                      accentColor: color,
                      projects: projects,
                      pursuit: pursuit,
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        PursuitSlotsBar(pursuit: pursuit, projects: projects),
      ],
    );
  }
}

class _EmptyTaskPlaceholder extends StatelessWidget {
  const _EmptyTaskPlaceholder({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist_outlined,
                size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No tasks queued',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add task" above to queue tasks from your active projects.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// A colour-coded, draggable task row in the unified task map.
class PursuitUnifiedTaskCard extends ConsumerWidget {
  const PursuitUnifiedTaskCard({
    super.key,
    required this.taskId,
    required this.projectId,
    required this.position,
    required this.accentColor,
    required this.projects,
    required this.pursuit,
  });

  final int taskId;
  final int? projectId;
  final int position;
  final Color accentColor;
  final List<ProjectData> projects;
  final PursuitFocusState pursuit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final theme = Theme.of(context);

    final projectName =
        projectId != null ? findProject(projectId!, projects)?.name : null;
    final taskIndexInQueue = projectId != null
        ? (pursuit.taskQueues[projectId]?.indexOf(taskId) ?? -1)
        : -1;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: accentColor, width: 5)),
      ),
      child: FutureBuilder<TaskData>(
        future: db.taskDao.getTaskById(taskId),
        builder: (context, snap) {
          final task = snap.data;
          // Hide cards for completed or deleted tasks — they should have been
          // cleaned up by the notifier but guard here for safety.
          if (task != null && (task.isCompleted || task.isDeleted)) {
            return const SizedBox.shrink();
          }

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            onTap: task != null
                ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TaskBreakdownScreen(task: task),
                      ),
                    )
                : null,
            leading: Text(
              '$position',
              style: theme.textTheme.labelLarge?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            title: Text(task?.name ?? '…', style: theme.textTheme.bodyMedium),
            subtitle: projectName != null
                ? Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          projectName,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                      if (taskIndexInQueue >= 0)
                        Text(
                          '  ·  #${taskIndexInQueue + 1} in project',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (task != null && projectId != null)
                  IconButton(
                    iconSize: 20,
                    icon: const Icon(Icons.check_circle_outline),
                    tooltip: 'Mark task complete',
                    onPressed: () =>
                        _confirmCompleteTask(context, ref, task),
                  ),
                if (projectId != null)
                  IconButton(
                    iconSize: 18,
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: 'Remove from queue',
                    onPressed: () {
                      final idx =
                          pursuit.taskQueues[projectId]?.indexOf(taskId) ??
                              -1;
                      if (idx >= 0) {
                        ref
                            .read(pursuitFocusNotifierProvider.notifier)
                            .removeTaskFromQueueAt(projectId!, idx);
                      }
                    },
                  ),
                const Icon(Icons.drag_handle),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmCompleteTask(
    BuildContext context,
    WidgetRef ref,
    TaskData task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete task?'),
        content: Text('Mark "${task.name}" as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref
        .read(projectTasksNotifier(task.projectId).notifier)
        .updateTask(task.id, const TaskCompanion(isCompleted: Value(true)));
  }
}
