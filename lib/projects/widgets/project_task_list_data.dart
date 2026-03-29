import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';
import 'package:potential_aid_app/projects/widgets/complete_task_dialog.dart';
import 'package:potential_aid_app/projects/widgets/task_list_item.dart';

class ProjectTaskListData extends ConsumerStatefulWidget {
  final int projectId;
  final List<TaskData> selectedTasks;
  final List<bool Function(TaskData)>? predicates;
  final String? query;
  final int? depthLevel;
  final bool editMode;
  final bool showCompleted;
  final void Function(List<TaskData>) onSelectionChanged;

  const ProjectTaskListData({
    super.key,
    required this.projectId,
    required this.selectedTasks,
    this.predicates,
    this.query,
    this.depthLevel,
    required this.editMode,
    this.showCompleted = false,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ProjectTaskListDataState();
}

class _ProjectTaskListDataState extends ConsumerState<ProjectTaskListData> {
  static const _initialCount = 3;
  bool _showAll = false;

  @override
  void didUpdateWidget(ProjectTaskListData oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear "show all" when the search query is cleared
    if (oldWidget.query != widget.query &&
        (widget.query == null || widget.query!.isEmpty)) {
      setState(() => _showAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(projectTasksNotifier(widget.projectId));

    return tasksAsync.when(
      data: (tasks) {
        // Depth filter
        if (widget.depthLevel != null) {
          tasks = tasks.where((t) => t.depth == widget.depthLevel).toList();
        } else {
          tasks = tasks.where((t) => t.depth == 0).toList();
        }
        // Query filter
        if (widget.query != null && widget.query!.isNotEmpty) {
          final q = widget.query!.toLowerCase();
          tasks = tasks.where((t) => t.name.toLowerCase().contains(q)).toList();
        }
        // Split (DAO already sorted uncompleted-first, orderIndex-second)
        final uncompleted = tasks.where((t) => !t.isCompleted).toList();
        final completed = tasks.where((t) => t.isCompleted).toList();
        return _buildList(uncompleted, completed, ref);
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Loading...'),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildList(
    List<TaskData> uncompleted,
    List<TaskData> completed,
    WidgetRef ref,
  ) {
    final isSearching = widget.query != null && widget.query!.isNotEmpty;
    // Show all when actively searching so results aren't hidden
    final effectiveShowAll = _showAll || isSearching;

    final hasMore = uncompleted.length > _initialCount;
    final visible = effectiveShowAll
        ? uncompleted
        : uncompleted.take(_initialCount).toList();

    final showCompletedSection = widget.showCompleted && completed.isNotEmpty;

    if (uncompleted.isEmpty && !showCompletedSection) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No tasks found..'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Uncompleted tasks ──────────────────────────────────────
          for (int i = 0; i < visible.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _item(visible[i], ref),
          ],

          // ── Show more / show less ──────────────────────────────────
          if (hasMore && !isSearching) ...[
            const SizedBox(height: 4),
            Center(
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _showAll = !effectiveShowAll),
                icon: Icon(
                  effectiveShowAll
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 16,
                ),
                label: Text(
                  effectiveShowAll
                      ? 'Show less'
                      : '${uncompleted.length - _initialCount} more',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],

          // ── Completed section ──────────────────────────────────────
          if (showCompletedSection) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 13,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Completed (${completed.length})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            for (int i = 0; i < completed.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _item(completed[i], ref),
            ],
          ],
        ],
      ),
    );
  }

  Widget _item(TaskData task, WidgetRef ref) {
    return TaskListItem(
      task: task,
      onComplete: () async => showCompleteTaskDialog(context, task),
      onDelete: () async => _deleteTask(ref, task),
      onSelect: () {
        final next = List<TaskData>.from(widget.selectedTasks);
        if (next.contains(task)) {
          next.remove(task);
        } else {
          next.add(task);
        }
        widget.onSelectionChanged(next);
      },
      editMode: widget.editMode,
      isSelected: widget.selectedTasks.contains(task),
    );
  }

  Future<void> _deleteTask(WidgetRef ref, TaskData task) async {
    await ref
        .read(projectTasksNotifier(task.projectId).notifier)
        .deleteTask(task.id);
  }
}
