import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/pursuit/providers/pursuit_focus_notifier.dart';
import 'package:potential_aid_app/providers/database_provider.dart';

class ProjectTasksNotifier extends StateNotifier<AsyncValue<List<TaskData>>> {
  final Ref _ref;
  final AppDatabase _database;
  final int projectId;

  ProjectTasksNotifier(this._ref, this._database, this.projectId)
    : super(const AsyncValue.loading()) {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _database.taskDao.getAllTasksByProject(projectId);
      if (mounted) {
        state = AsyncValue.data(tasks);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadTasks();
  }

  Future<TaskData> getTask(int taskId) async {
    return await _database.taskDao.getTaskById(taskId);
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
    final before = await _database.taskDao.getTaskById(taskId);
    final result = await _database.taskDao.updateTask(taskId, updates);
    final after = await _database.taskDao.getTaskById(taskId);
    if (!before.isCompleted && after.isCompleted) {
      final notifier = _ref.read(pursuitFocusNotifierProvider.notifier);
      await notifier.onTaskCompleted(after.id, after.projectId);

      final descendants =
          await _database.taskDao.getAllDescendantsRecursive(after.id);
      final completedIds = descendants
          .where((d) => d.isCompleted)
          .map((d) => d.id)
          .toList();
      if (completedIds.isNotEmpty) {
        await notifier.onTasksCompleted(completedIds, after.projectId);
      }
    }
    await refresh();
    return result;
  }

  /// Updates the task without triggering a state refresh.
  /// Use this inside batch loops; call [refresh] once when the batch is done.
  Future<int> updateTaskSilent(int taskId, TaskCompanion updates) async {
    return await _database.taskDao.updateTask(taskId, updates);
  }

  Future<void> deleteTask(int taskId) async {
    await _database.taskDao.deleteTask(taskId);
    await refresh();
  }

  Future<List<TaskData>> getSubtasks(
    int taskId, [
    List<Expression<bool> Function($TaskTable)>? predicates,
  ]) async {
    return await _database.taskDao.getSubtasks(taskId, predicates);
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
      return ProjectTasksNotifier(ref, database, projectId);
    });
