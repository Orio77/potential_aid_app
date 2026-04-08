import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';

/// Root-level tasks (`parentTaskId == null`), ordered like [TaskDao.getFirstDepthTasksForProject].
///
/// Derived from [projectTasksNotifier] so the project header stays in sync whenever
/// tasks refresh (list completions, breakdown, schedule, dialogs, etc.).
List<TaskData> firstDepthTasksFromProjectTasks(List<TaskData> tasks) {
  final roots = tasks.where((t) => t.parentTaskId == null).toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  return roots;
}

final firstDepthTasksProvider =
    Provider.autoDispose.family<AsyncValue<List<TaskData>>, int>((ref, projectId) {
  return ref.watch(projectTasksNotifier(projectId)).when(
        data: (tasks) =>
            AsyncValue.data(firstDepthTasksFromProjectTasks(tasks)),
        error: (e, st) => AsyncValue.error(e, st),
        loading: () => const AsyncValue.loading(),
      );
});

/// Direct subtasks of a given task.
final taskSubtasksProvider =
    FutureProvider.autoDispose.family<List<TaskData>, int>((ref, taskId) {
  return ref.read(databaseProvider).taskDao.getSubtasks(taskId, null);
});
