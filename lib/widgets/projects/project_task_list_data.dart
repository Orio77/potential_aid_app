import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';
import 'package:potential_aid_app/widgets/projects/complete_task_dialog.dart';
import 'package:potential_aid_app/widgets/projects/task_list_item.dart';

class ProjectTaskListData extends ConsumerStatefulWidget {
  final int projectId;
  final List<TaskData> selectedTasks;
  final List<bool Function(TaskData)>? predicates;
  final String? query;
  final int? depthLevel;
  final bool editMode;
  final void Function(List<TaskData>) onSelectionChanged;

  const ProjectTaskListData({
    super.key,
    required this.projectId,
    required this.selectedTasks,
    this.predicates,
    this.query,
    this.depthLevel,
    required this.editMode,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ProjectTaskListDataState();
}

class _ProjectTaskListDataState extends ConsumerState<ProjectTaskListData> {
  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(projectTasksNotifier(widget.projectId));

    return tasksAsync.when(
      data: (tasks) {
        if (widget.query != null) {
          tasks = tasks
              .where(
                (t) =>
                    t.name.toLowerCase().contains(widget.query!.toLowerCase()),
              )
              .toList();
        }
        if (widget.depthLevel != null) {
          tasks = tasks.where((t) => t.depth == widget.depthLevel).toList();
        } else {
          tasks = tasks.where((t) => t.depth == 0).toList();
        }
        return _buildTaskList(tasks, ref);
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildTaskList(List<TaskData> taskList, WidgetRef ref) {
    if (taskList.isEmpty) {
      return _buildEmptyState();
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => TaskListItem(
          task: taskList[index],
          onComplete: () async =>
              await showCompleteTaskDialog(context, taskList[index]),
          onDelete: () async => await _deleteTask(ref, taskList[index]),
          onSelect: () {
            final newSelectedTasks = List<TaskData>.from(widget.selectedTasks);
            if (newSelectedTasks.contains(taskList[index])) {
              newSelectedTasks.remove(taskList[index]);
            } else {
              newSelectedTasks.add(taskList[index]);
            }
            widget.onSelectionChanged(newSelectedTasks);
          },
          editMode: widget.editMode,
          isSelected: widget.selectedTasks.contains(taskList[index]),
        ),
        separatorBuilder: (context, index) => SizedBox(height: 8),
        itemCount: taskList.length,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Text('Loading...');
  }

  Widget _buildErrorState(Object error) {
    return Text('Error: $error');
  }

  Widget _buildEmptyState() {
    return Text('No tasks found..');
  }

  Future<void> _deleteTask(WidgetRef ref, TaskData task) async {
    await ref
        .read(projectTasksNotifier(task.projectId).notifier)
        .deleteTask(task.id);
  }
}
