import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/breakdown/screens/task_breakdown_screen.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/projects/screens/project_screen.dart';
import 'package:potential_aid_app/pursuit/models/pursuit_focus_state.dart';
import 'package:potential_aid_app/pursuit/providers/pursuit_focus_notifier.dart';
import 'package:potential_aid_app/pursuit/widgets/pursuit_colors.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';

class _TaskResult {
  const _TaskResult({required this.task, required this.projectId});
  final TaskData task;
  final int projectId;
}

/// [SearchDelegate] that searches open tasks across all active pursuit slots.
/// Completed and deleted tasks are excluded from results.
class PursuitSearchDelegate extends SearchDelegate<void> {
  PursuitSearchDelegate({
    required this.activeProjectIds,
    required this.db,
    required this.projects,
    required this.ref,
    required this.slots,
  });

  final List<int> activeProjectIds;
  final AppDatabase db;
  final List<ProjectData> projects;
  final WidgetRef ref;
  final List<int?> slots;

  /// Loads all open (non-completed, non-deleted) tasks for the active projects.
  Future<List<_TaskResult>> _loadOpenTasks() async {
    final results = <_TaskResult>[];
    for (final pid in activeProjectIds) {
      final tasks = await db.taskDao.getAllTasksByProject(pid);
      for (final t in tasks) {
        if (!t.isCompleted && !t.isDeleted) {
          results.add(_TaskResult(task: t, projectId: pid));
        }
      }
    }
    // Sort alphabetically by task name for a stable, predictable list.
    results.sort((a, b) => a.task.name.compareTo(b.task.name));
    return results;
  }

  List<_TaskResult> _filter(List<_TaskResult> all) {
    if (query.trim().isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((r) => r.task.name.toLowerCase().contains(q)).toList();
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear',
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) =>
      BackButton(onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _ResultsList(
        future: _loadOpenTasks(),
        filter: _filter,
        query: query,
        projects: projects,
        slots: slots,
        ref: ref,
        onClose: () => close(context, null),
        onRefresh: () => showResults(context),
      );

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}

/// Stateless list widget driven by a future so [SearchDelegate] stays minimal.
class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.future,
    required this.filter,
    required this.query,
    required this.projects,
    required this.slots,
    required this.ref,
    required this.onClose,
    required this.onRefresh,
  });

  final Future<List<_TaskResult>> future;
  final List<_TaskResult> Function(List<_TaskResult>) filter;
  final String query;
  final List<ProjectData> projects;
  final List<int?> slots;
  final WidgetRef ref;
  final VoidCallback onClose;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_TaskResult>>(
      future: future,
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final filtered = filter(snap.data!);
        if (filtered.isEmpty) {
          return Center(
            child: Text(
              query.trim().isEmpty
                  ? 'No open tasks in active projects'
                  : 'No results for "$query"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          );
        }
        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (_, i) =>
              _TaskResultTile(
                item: filtered[i],
                projects: projects,
                slots: slots,
                ref: ref,
                onClose: onClose,
                onRefresh: onRefresh,
              ),
        );
      },
    );
  }
}

class _TaskResultTile extends StatelessWidget {
  const _TaskResultTile({
    required this.item,
    required this.projects,
    required this.slots,
    required this.ref,
    required this.onClose,
    required this.onRefresh,
  });

  final _TaskResult item;
  final List<ProjectData> projects;
  final List<int?> slots;
  final WidgetRef ref;
  final VoidCallback onClose;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final color = projectColor(item.projectId, projects, slots);
    final projectName =
        findProject(item.projectId, projects)?.name ?? '#${item.projectId}';
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: ListTile(
        onTap: () {
          onClose();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TaskBreakdownScreen(task: item.task),
            ),
          );
        },
        title: Text(item.task.name),
        subtitle: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Flexible(
              child: Text(
                projectName,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle_outline, size: 20),
              tooltip: 'Mark complete',
              onPressed: () async {
                await ref
                    .read(projectTasksNotifier(item.projectId).notifier)
                    .updateTask(
                      item.task.id,
                      const TaskCompanion(isCompleted: Value(true)),
                    );
                // ignore: invalid_use_of_protected_member
                if (context.mounted) onRefresh();
              },
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 18),
              tooltip: 'Open project',
              onPressed: () {
                final project = findProject(item.projectId, projects);
                if (project == null) return;
                onClose();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProjectScreen(data: project),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Project search ────────────────────────────────────────────────────────────

/// [SearchDelegate] that searches undeleted, uncompleted projects.
/// Tapping a result adds the project to the pursuit backlog queue.
class PursuitProjectSearchDelegate extends SearchDelegate<void> {
  PursuitProjectSearchDelegate({
    required this.projects,
    required this.pursuit,
    required this.ref,
  });

  final List<ProjectData> projects;
  final PursuitFocusState pursuit;
  final WidgetRef ref;

  List<ProjectData> get _eligible => projects
      .where((p) => !p.isDeleted && p.current < p.goal)
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  List<ProjectData> _filter(List<ProjectData> all) {
    if (query.trim().isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear',
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) =>
      BackButton(onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) =>
      _ProjectResultsList(
        filtered: _filter(_eligible),
        query: query,
        pursuit: pursuit,
        ref: ref,
        onClose: () => close(context, null),
      );

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}

class _ProjectResultsList extends StatelessWidget {
  const _ProjectResultsList({
    required this.filtered,
    required this.query,
    required this.pursuit,
    required this.ref,
    required this.onClose,
  });

  final List<ProjectData> filtered;
  final String query;
  final PursuitFocusState pursuit;
  final WidgetRef ref;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          query.trim().isEmpty
              ? 'No active projects found'
              : 'No results for "$query"',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (_, i) => _ProjectResultTile(
        project: filtered[i],
        pursuit: pursuit,
        ref: ref,
        onClose: onClose,
      ),
    );
  }
}

class _ProjectResultTile extends StatelessWidget {
  const _ProjectResultTile({
    required this.project,
    required this.pursuit,
    required this.ref,
    required this.onClose,
  });

  final ProjectData project;
  final PursuitFocusState pursuit;
  final WidgetRef ref;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(project.color ?? 0xFF9E9E9E);
    final inSlot = pursuit.slots.contains(project.id);
    final inQueue = pursuit.projectQueue.contains(project.id);
    final statusLabel = inSlot
        ? 'In active slot'
        : inQueue
            ? 'Already in queue'
            : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: ListTile(
        onTap: inSlot || inQueue
            ? null
            : () async {
                await ref
                    .read(pursuitFocusNotifierProvider.notifier)
                    .addProjectToBacklog(project.id);
                if (context.mounted) onClose();
              },
        title: Text(project.name),
        subtitle: statusLabel != null
            ? Text(
                statusLabel,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!inSlot && !inQueue)
              IconButton(
                icon: const Icon(Icons.playlist_add, size: 20),
                tooltip: 'Add to queue',
                onPressed: () async {
                  await ref
                      .read(pursuitFocusNotifierProvider.notifier)
                      .addProjectToBacklog(project.id);
                  if (context.mounted) onClose();
                },
              ),
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 18),
              tooltip: 'Open project',
              onPressed: () {
                onClose();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProjectScreen(data: project),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
