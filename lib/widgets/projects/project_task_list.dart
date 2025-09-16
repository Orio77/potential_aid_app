import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';
import 'package:potential_aid_app/widgets/projects/task_list_item.dart';

class ProjectTaskList extends ConsumerWidget {
  final int projectId;

  const ProjectTaskList({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(projectTasksNotifier(projectId));

    return tasksAsync.when(
      data: (tasks) => _buildTaskList(tasks, ref),
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
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) => TaskListItem(
          task: taskList[index],
          onDelete: () => _deleteTask(ref, taskList[index]),
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
    return Text('Empty');
  }

  Future<void> _deleteTask(WidgetRef ref, TaskData task) async {
    await ref
        .read(projectTasksNotifier(task.projectId).notifier)
        .deleteTask(task.id);
  }
}
