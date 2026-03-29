import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';

/// First-depth tasks (no parent) for a given project. Includes completed tasks
/// so the global progress bar reflects the full picture.
final firstDepthTasksProvider =
    FutureProvider.autoDispose.family<List<TaskData>, int>((ref, projectId) {
  return ref
      .read(databaseProvider)
      .taskDao
      .getFirstDepthTasksForProject(projectId);
});

/// Direct subtasks of a given task.
final taskSubtasksProvider =
    FutureProvider.autoDispose.family<List<TaskData>, int>((ref, taskId) {
  return ref.read(databaseProvider).taskDao.getSubtasks(taskId, null);
});
