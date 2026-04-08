import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/task_search_notifier.dart';
import 'package:potential_aid_app/schedule/widgets/block_task_row.dart';
import 'package:potential_aid_app/widgets/util/search_text_field.dart';

class BlockAddTaskList extends ConsumerStatefulWidget {
  final ProjectData? project;
  final List<TaskData>? initialTasks;
  final void Function(List<TaskData>) onTasksChanged;
  const BlockAddTaskList({
    super.key,
    required this.project,
    this.initialTasks,
    required this.onTasksChanged,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<BlockAddTaskList> {
  late List<TaskData> _tasks;
  List<bool Function(TaskData)> _predicates = <bool Function(TaskData)>[];
  late final TextEditingController _taskNameController;

  @override
  void initState() {
    super.initState();
    _tasks = widget.initialTasks ?? <TaskData>[];
    _taskNameController = TextEditingController();
    _updatePredicates();
  }

  @override
  void didUpdateWidget(BlockAddTaskList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.project?.id != oldWidget.project?.id) {
      setState(() {
        _tasks = List.from(widget.initialTasks ?? []);
        _taskNameController.clear();
      });

      widget.onTasksChanged(_tasks);
      _updatePredicates();
    } else {}
  }

  void _updatePredicates() {
    _predicates = widget.project != null
        ? [(task) => task.projectId == widget.project!.id]
        : [];

    _predicates.add((task) => !task.isCompleted);
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    super.dispose();
  }

  Widget _buildAddTasksView(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchTextField(
          controller: _taskNameController,
          labelText: 'Search project tasks',
          searchProvider: taskSearchProvider,
          onItemSelected: (task) => _addTaskToList(task),
          getDisplayText: (task) => task.name,
          predicates: _predicates,
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(Icons.checklist_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Tasks in this block',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${_tasks.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Material(
            color: cs.surfaceContainerHighest,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.9)),
            ),
            clipBehavior: Clip.antiAlias,
            child: _tasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.playlist_add_check_outlined,
                            size: 36,
                            color: cs.outline,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No tasks yet',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: cs.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pick tasks from the search field above',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.35,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _tasks.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: cs.outlineVariant),
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return BlockTaskRow(
                        task: task,
                        dense: true,
                        trailing: IconButton(
                          tooltip: 'Remove task',
                          onPressed: () => _removeTaskFromList(index),
                          icon: Icon(
                            Icons.remove_circle_outline_rounded,
                            color: cs.error,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  void _addTaskToList(TaskData task) {
    if (!_tasks.any((existingTask) => existingTask.id == task.id)) {
      setState(() {
        _tasks.add(task);
        _taskNameController.clear();
      });
      widget.onTasksChanged(_tasks);
    } else {}
  }

  void _removeTaskFromList(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    widget.onTasksChanged(_tasks);
  }

  @override
  Widget build(BuildContext context) {
    return widget.project != null
        ? _buildAddTasksView(context)
        : const SizedBox.shrink();
  }
}
