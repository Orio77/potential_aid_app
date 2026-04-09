import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/pursuit/providers/pursuit_focus_notifier.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';

/// Shows a bottom sheet listing projects that are not yet in a slot or the
/// queue. Only non-deleted, active (current < goal) projects are included.
Future<int?> showProjectPicker(BuildContext context, WidgetRef ref) async {
  final projects = ref.read(projectsNotifierProvider);
  final pursuit = ref.read(pursuitFocusNotifierProvider);
  final taken = <int>{
    ...pursuit.slots.whereType<int>(),
    ...pursuit.projectQueue,
  };

  // projectsNotifierProvider already filters current < goal; guard isDeleted too.
  final available = projects
      .where((p) => !taken.contains(p.id) && !p.isDeleted)
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Choose project',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: available.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child:
                          Text('All active projects are already slotted or queued.'),
                    ),
                  )
                : ListView.builder(
                    controller: controller,
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
    ),
  );
}

/// Shows a bottom sheet listing uncompleted, non-deleted, non-queued root-level
/// tasks for [projectId].
Future<int?> showTaskPicker(
  BuildContext context,
  WidgetRef ref,
  int projectId,
) async {
  final db = ref.read(databaseProvider);
  final allTasks = await db.taskDao.getFirstDepthTasksForProject(projectId);

  final pursuit = ref.read(pursuitFocusNotifierProvider);
  final alreadyQueued = pursuit.taskQueues[projectId]?.toSet() ?? {};

  // Only show tasks that are open, not deleted, and not already in the queue.
  final pickable = allTasks
      .where((t) =>
          !t.isCompleted && !t.isDeleted && !alreadyQueued.contains(t.id))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  if (!context.mounted) return null;

  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Add task to queue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: pickable.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                          'No open tasks available to add for this project.'),
                    ),
                  )
                : ListView.builder(
                    controller: controller,
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
    ),
  );
}
