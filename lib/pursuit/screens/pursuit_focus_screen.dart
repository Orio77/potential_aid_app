import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/pursuit/models/pursuit_focus_state.dart';
import 'package:potential_aid_app/pursuit/providers/pursuit_focus_notifier.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';

class PursuitFocusScreen extends ConsumerWidget {
  const PursuitFocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pursuit = ref.watch(pursuitFocusNotifierProvider);
    final projects = ref.watch(projectsNotifierProvider);
    final theme = Theme.of(context);

    String nameFor(int? id) {
      if (id == null) return 'Empty slot';
      for (final p in projects) {
        if (p.id == id) return p.name;
      }
      return 'Project #$id';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pursuit Focus'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(pursuitFocusNotifierProvider.notifier).reload(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
          Text(
            'Active projects (max 3)',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < PursuitFocusState.slotCount; i++)
            _SlotCard(
              index: i,
              projectId: pursuit.slots[i],
              title: 'Slot ${i + 1}',
              subtitle: nameFor(pursuit.slots[i]),
              taskQueue: pursuit.slots[i] != null
                  ? pursuit.taskQueues[pursuit.slots[i]] ?? const []
                  : const [],
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Project queue',
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () => _pickProjectForBacklog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (pursuit.projectQueue.isEmpty)
            Text(
              'No projects queued. When an active project reaches its goal, '
              'the next queued project fills that slot.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            _BacklogList(projectIds: pursuit.projectQueue),
        ],
        ),
      ),
    );
  }

  static Future<void> _pickProjectForBacklog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final id = await showProjectPicker(context, ref);
    if (id != null && context.mounted) {
      await ref.read(pursuitFocusNotifierProvider.notifier).addProjectToBacklog(id);
    }
  }
}

class _SlotCard extends ConsumerWidget {
  const _SlotCard({
    required this.index,
    required this.projectId,
    required this.title,
    required this.subtitle,
    required this.taskQueue,
  });

  final int index;
  final int? projectId;
  final String title;
  final String subtitle;
  final List<int> taskQueue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final db = ref.watch(databaseProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.labelLarge),
                      Text(
                        subtitle,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Choose project',
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: () async {
                    final id = await showProjectPicker(context, ref);
                    if (!context.mounted) return;
                    await ref
                        .read(pursuitFocusNotifierProvider.notifier)
                        .setSlot(index, id);
                  },
                ),
                if (projectId != null)
                  IconButton(
                    tooltip: 'Clear slot',
                    icon: const Icon(Icons.clear),
                    onPressed: () => ref
                        .read(pursuitFocusNotifierProvider.notifier)
                        .setSlot(index, null),
                  ),
              ],
            ),
            if (projectId != null) ...[
              const Divider(),
              Row(
                children: [
                  Text(
                    'Task queue',
                    style: theme.textTheme.titleSmall,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      final tid = await showTaskPicker(
                        context,
                        ref,
                        projectId!,
                      );
                      if (!context.mounted) return;
                      if (tid != null) {
                        await ref
                            .read(pursuitFocusNotifierProvider.notifier)
                            .addTaskToQueue(projectId!, tid);
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add task'),
                  ),
                ],
              ),
                _TaskQueueList(projectId: projectId!, taskIds: taskQueue, db: db),
            ],
          ],
        ),
      ),
    );
  }
}

class _BacklogList extends ConsumerStatefulWidget {
  const _BacklogList({required this.projectIds});

  final List<int> projectIds;

  @override
  ConsumerState<_BacklogList> createState() => _BacklogListState();
}

class _BacklogListState extends ConsumerState<_BacklogList> {
  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsNotifierProvider);

    String nameFor(int id) {
      for (final p in projects) {
        if (p.id == id) return p.name;
      }
      return 'Project #$id';
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.projectIds.length,
      onReorder: (oldIdx, newIdx) {
        ref
            .read(pursuitFocusNotifierProvider.notifier)
            .reorderBacklog(oldIdx, newIdx);
      },
      itemBuilder: (context, index) {
        final id = widget.projectIds[index];
        return ListTile(
          key: ValueKey('backlog_$id'),
          leading: const Icon(Icons.drag_handle),
          title: Text(nameFor(id)),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => ref
                .read(pursuitFocusNotifierProvider.notifier)
                .removeProjectFromBacklogAt(index),
          ),
        );
      },
    );
  }
}

class _TaskQueueList extends ConsumerStatefulWidget {
  const _TaskQueueList({
    required this.projectId,
    required this.taskIds,
    required this.db,
  });

  final int projectId;
  final List<int> taskIds;
  final AppDatabase db;

  @override
  ConsumerState<_TaskQueueList> createState() => _TaskQueueListState();
}

class _TaskQueueListState extends ConsumerState<_TaskQueueList> {
  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.taskIds.length,
      onReorder: (oldIdx, newIdx) {
        ref
            .read(pursuitFocusNotifierProvider.notifier)
            .reorderTaskQueue(widget.projectId, oldIdx, newIdx);
      },
      itemBuilder: (context, index) {
        final tid = widget.taskIds[index];
        return FutureBuilder<TaskData>(
          future: widget.db.taskDao.getTaskById(tid),
          builder: (context, snap) {
            final name = snap.data?.name ?? '…';
            return ListTile(
              key: ValueKey('tq_${widget.projectId}_$tid'),
              leading: Text(
                '${index + 1}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              title: Text(name),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => ref
                    .read(pursuitFocusNotifierProvider.notifier)
                    .removeTaskFromQueueAt(widget.projectId, index),
              ),
            );
          },
        );
      },
    );
  }
}

Future<int?> showProjectPicker(BuildContext context, WidgetRef ref) async {
  final projects = ref.read(projectsNotifierProvider);
  final pursuit = ref.read(pursuitFocusNotifierProvider);
  final taken = <int>{
    ...pursuit.slots.whereType<int>(),
    ...pursuit.projectQueue,
  };

  final available = projects.where((p) => !taken.contains(p.id)).toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choose project',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Flexible(
              child: available.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('All projects are already in slots or queue.'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: available.length,
                      itemBuilder: (_, i) {
                        final p = available[i];
                        return ListTile(
                          title: Text(p.name),
                          onTap: () => Navigator.pop(ctx, p.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    },
  );
}

Future<int?> showTaskPicker(
  BuildContext context,
  WidgetRef ref,
  int projectId,
) async {
  final db = ref.read(databaseProvider);
  final tasks = await db.taskDao.getFirstDepthTasksForProject(projectId);
  final open = tasks.where((t) => !t.isCompleted).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  final pursuit = ref.read(pursuitFocusNotifierProvider);
  final queued = pursuit.taskQueues[projectId]?.toSet() ?? {};

  final pickable = open.where((t) => !queued.contains(t.id)).toList();

  if (!context.mounted) return null;

  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Add task to queue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Flexible(
              child: pickable.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No uncompleted root-level tasks available to add.',
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: pickable.length,
                      itemBuilder: (_, i) {
                        final t = pickable[i];
                        return ListTile(
                          title: Text(t.name),
                          onTap: () => Navigator.pop(ctx, t.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    },
  );
}
