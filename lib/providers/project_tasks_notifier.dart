import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';

class ProjectTasksNotifier extends StateNotifier<AsyncValue<List<TaskData>>> {
  final AppDatabase _database;
  final int projectId;

  ProjectTasksNotifier(this._database, this.projectId)
    : super(const AsyncValue.loading()) {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _database.taskDao.getTasksByProject(projectId);
      state = AsyncValue.data(tasks);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadTasks();
  }

  Future<int> addTask(
    String name,
    int projectId,
    DateTime deadline, [
    String? unit,
    int? startPoint,
    int? current,
    int? endGoal,
  ]) async {
    int taskId = await _database.taskDao.addTask(
      name,
      projectId,
      deadline,
      unit,
      startPoint,
      current,
      endGoal,
    );

    await refresh();

    return taskId;
  }
}

final projectTasksNotifier =
    StateNotifierProvider.family<
      ProjectTasksNotifier,
      AsyncValue<List<TaskData>>,
      int
    >((ref, projectId) {
      final database = ref.watch(databaseProvider);
      return ProjectTasksNotifier(database, projectId);
    });
