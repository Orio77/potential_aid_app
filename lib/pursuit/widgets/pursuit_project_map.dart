import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/projects/screens/project_screen.dart';
import 'package:potential_aid_app/pursuit/models/pursuit_focus_state.dart';
import 'package:potential_aid_app/pursuit/providers/pursuit_focus_notifier.dart';
import 'package:potential_aid_app/pursuit/widgets/pursuit_colors.dart';
import 'package:potential_aid_app/pursuit/widgets/pursuit_slots_bar.dart';

/// Project-map view: a scrollable, reversed queue of upcoming projects above
/// the fixed three active-slot cards at the bottom.
class PursuitProjectMapBody extends ConsumerWidget {
  const PursuitProjectMapBody({
    super.key,
    required this.pursuit,
    required this.projects,
  });

  final PursuitFocusState pursuit;
  final List<ProjectData> projects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Hide queue entries for projects that are no longer active / exist.
    final activeIds = {
      ...pursuit.slots.whereType<int>(),
      ...pursuit.projectQueue,
    };
    final visibleQueue = pursuit.projectQueue
        .where((pid) =>
            activeIds.contains(pid) &&
            findProject(pid, projects) != null)
        .toList();

    return Column(
      children: [
        Expanded(
          child: visibleQueue.isEmpty
              ? _EmptyQueuePlaceholder(theme: theme)
              : ReorderableListView.builder(
                  // index 0 sits at the bottom (activates next);
                  // higher indices float upward into the future.
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 64, 16, 8),
                  onReorder: (oldIdx, newIdx) => ref
                      .read(pursuitFocusNotifierProvider.notifier)
                      .reorderBacklog(oldIdx, newIdx),
                  itemCount: visibleQueue.length,
                  itemBuilder: (ctx, index) {
                    final pid = visibleQueue[index];
                    return PursuitQueueProjectCard(
                      key: ValueKey('queue_$pid'),
                      pid: pid,
                      position: index,
                      projects: projects,
                      onRemove: () => ref
                          .read(pursuitFocusNotifierProvider.notifier)
                          .removeProjectFromBacklogAt(index),
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

class _EmptyQueuePlaceholder extends StatelessWidget {
  const _EmptyQueuePlaceholder({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.queue_outlined,
                size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No projects queued',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add to queue" above. When a slot finishes its goal '
              'the next queued project moves in automatically.',
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

/// A single draggable card in the project queue.
class PursuitQueueProjectCard extends ConsumerWidget {
  const PursuitQueueProjectCard({
    super.key,
    required this.pid,
    required this.position,
    required this.projects,
    required this.onRemove,
  });

  final int pid;
  final int position;
  final List<ProjectData> projects;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final project = findProject(pid, projects);
    final name = project?.name ?? 'Project #$pid';
    final color = projectColor(pid, projects, []);
    final isNext = position == 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        title: Text(name, style: theme.textTheme.titleSmall),
        subtitle: Text(
          isNext ? 'Next to activate' : 'Position ${position + 1} in queue',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (project != null)
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 18),
                tooltip: 'Open project',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProjectScreen(data: project),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              tooltip: 'Remove from queue',
              onPressed: onRemove,
            ),
            const Icon(Icons.drag_handle),
          ],
        ),
      ),
    );
  }
}
