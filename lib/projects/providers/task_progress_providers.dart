import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';

/// Root-level tasks (`parentTaskId == null`), ordered like [TaskDao.getFirstDepthTasksForProject].
///
/// Derived from [projectTasksNotifier] so the project header stays in sync whenever
/// tasks refresh (list completions, breakdown, schedule, dialogs, etc.).
///
/// NOTE: [projectTasksNotifier] only exposes *open* tasks (the underlying
/// `getAllTasksByProject` filters out completed ones at the SQL level), so
/// this list intentionally excludes completed tasks. Use
/// [firstDepthTasksWithCompletedProvider] when you need completed roots too
/// (e.g. for overall progress averages).
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

/// Root-level tasks including *completed* ones (still excludes deleted).
///
/// Queried directly from the DB via [TaskDao.getFirstDepthTasksForProject] so
/// completed tasks are included. Re-runs whenever [projectTasksNotifier]
/// changes, so completing / editing / adding a task refreshes this too.
final firstDepthTasksWithCompletedProvider =
    FutureProvider.autoDispose.family<List<TaskData>, int>((ref, projectId) async {
  // Invalidate when the project's task set changes.
  ref.watch(projectTasksNotifier(projectId));
  final db = ref.read(databaseProvider);
  return db.taskDao.getFirstDepthTasksForProject(projectId);
});

/// Direct subtasks of a given task.
final taskSubtasksProvider =
    FutureProvider.autoDispose.family<List<TaskData>, int>((ref, taskId) {
  return ref.read(databaseProvider).taskDao.getSubtasks(taskId, null);
});
