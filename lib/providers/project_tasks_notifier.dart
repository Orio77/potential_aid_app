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

  Future<TaskData> getTask(int taskId) async {
    return await _database.taskDao.getTask(taskId);
  }

  Future<TaskData?> getParent(int taskId) async {
    return await _database.taskDao.getParentTask(taskId);
  }

  Future<int> addTask(
    String name,
    int projectId,
    DateTime deadline, {
    String? unit,
    int? startPoint,
    int? current,
    int? endGoal,
    int? parentTaskId,
    int? depth,
    int? orderIndex,
  }) async {
    int taskId = await _database.taskDao.addTask(
      name,
      projectId,
      deadline,
      unit,
      startPoint,
      current,
      endGoal,
      parentTaskId,
      depth,
      orderIndex,
    );

    await refresh();

    return taskId;
  }

  Future<int> updateTask(int taskId, TaskCompanion updates) async {
    return await _database.taskDao.updateTask(taskId, updates);
  }

  Future<void> deleteTask(int taskId) async {
    await _database.taskDao.deleteTask(taskId);
  }

  Future<List<TaskData>> getSubtasks(int taskId) async {
    return await _database.taskDao.getSubtasks(taskId);
  }

  Future<List<TaskData>> getAllDescendants(int taskId) async {
    return await _database.taskDao.getAllDescendantsRecursive(taskId);
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
