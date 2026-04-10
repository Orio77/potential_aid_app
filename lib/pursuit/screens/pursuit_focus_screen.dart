import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/pursuit/models/pursuit_focus_state.dart';
import 'package:potential_aid_app/pursuit/providers/pursuit_focus_notifier.dart';
import 'package:potential_aid_app/pursuit/widgets/pursuit_pickers.dart';
import 'package:potential_aid_app/pursuit/widgets/pursuit_project_map.dart';
import 'package:potential_aid_app/pursuit/widgets/pursuit_search.dart';
import 'package:potential_aid_app/pursuit/widgets/pursuit_task_map.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';

class PursuitFocusScreen extends ConsumerStatefulWidget {
  const PursuitFocusScreen({super.key});

  @override
  ConsumerState<PursuitFocusScreen> createState() => _PursuitFocusScreenState();
}

class _PursuitFocusScreenState extends ConsumerState<PursuitFocusScreen> {
  bool _taskView = false;

  @override
  Widget build(BuildContext context) {
    final pursuit = ref.watch(pursuitFocusNotifierProvider);
    final projects = ref.watch(projectsNotifierProvider);
    final db = ref.watch(databaseProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.inversePrimary,
        scrolledUnderElevation: 0,
        title: _taskView
            ? _AddTaskButton(pursuit: pursuit)
            : _AddToQueueButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: _taskView ? 'Search tasks' : 'Search projects',
            onPressed: () {
              if (_taskView) {
                final activeIds = pursuit.slots.whereType<int>().toList();
                showSearch(
                  context: context,
                  delegate: PursuitSearchDelegate(
                    activeProjectIds: activeIds,
                    db: db,
                    projects: projects,
                    ref: ref,
                    slots: pursuit.slots,
                  ),
                );
              } else {
                showSearch(
                  context: context,
                  delegate: PursuitProjectSearchDelegate(
                    projects: projects,
                    pursuit: pursuit,
                    ref: ref,
                  ),
                );
              }
            },
          ),
          IconButton(
            tooltip: _taskView ? 'Project view' : 'Task view',
            icon: Icon(_taskView
                ? Icons.account_tree_outlined
                : Icons.view_list_outlined),
            onPressed: () => setState(() => _taskView = !_taskView),
          ),
        ],
      ),
      body: _taskView
          ? PursuitTaskMapBody(pursuit: pursuit, projects: projects)
          : PursuitProjectMapBody(pursuit: pursuit, projects: projects),
    );
  }
}

// ── AppBar action buttons ─────────────────────────────────────────────────────

class _AddToQueueButton extends ConsumerWidget {
  const _AddToQueueButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      icon: const Icon(Icons.add),
      label: const Text('Add to queue'),
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onInverseSurface,
      ),
      onPressed: () async {
        final id = await showProjectPicker(context, ref);
        if (id != null && context.mounted) {
          await ref
              .read(pursuitFocusNotifierProvider.notifier)
              .addProjectToBacklog(id);
        }
      },
    );
  }
}

class _AddTaskButton extends ConsumerWidget {
  const _AddTaskButton({required this.pursuit});

  final PursuitFocusState pursuit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      icon: const Icon(Icons.add_task),
      label: const Text('Add task'),
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onInverseSurface,
      ),
      onPressed: () async {
        final activeSlots = pursuit.slots.whereType<int>().toList();
        if (activeSlots.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add a project to a slot first.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        final pid = activeSlots.length == 1
            ? activeSlots.first
            : await _pickSlotProject(context, ref, activeSlots);
        if (pid == null || !context.mounted) return;

        final tid = await showTaskPicker(context, ref, pid);
        if (tid != null && context.mounted) {
          await ref
              .read(pursuitFocusNotifierProvider.notifier)
              .addTaskToQueue(pid, tid);
        }
      },
    );
  }

  Future<int?> _pickSlotProject(
      BuildContext context, WidgetRef ref, List<int> pids) {
    final projects = ref.read(projectsNotifierProvider);

    return showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Which project?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            for (final pid in pids)
              ListTile(
                title: Text(
                  projects
                          .where((p) => p.id == pid)
                          .cast<ProjectData?>()
                          .firstOrNull
                          ?.name ??
                      'Project #$pid',
                ),
                onTap: () => Navigator.pop(ctx, pid),
              ),
          ],
        ),
      ),
    );
  }
}
