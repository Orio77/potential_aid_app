import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';

class TasksNotifierProvider extends StateNotifier<List<TaskData>> {
  final AppDatabase _database;
  List<Expression<bool> Function($TaskTable)>? predicates;
  TasksNotifierProvider(this._database, this.predicates) : super([]) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    final tasks = await _database.taskDao.getAllTasks(predicates);
    if (mounted) {
      state = tasks;
    }
  }

  Future<void> updateTask(int taskId, TaskCompanion taskCompanion) async {
    await _database.taskDao.updateTask(taskId, taskCompanion);
    await loadTasks();
  }

  Future<List<TaskData>> getAllSubtasks(int taskId) async {
    return await _database.taskDao.getAllDescendantsRecursive(taskId);
  }
}

final tasksNotifierProvider =
    StateNotifierProvider.family<
      TasksNotifierProvider,
      List<TaskData>,
      List<Expression<bool> Function($TaskTable)>?
    >((ref, predicates) {
      final database = ref.watch(databaseProvider);
      return TasksNotifierProvider(database, predicates);
    });

final taskCountForDateProvider =
    StreamProvider.family<int, DateTime>((ref, date) {
  final database = ref.watch(databaseProvider);
  final startOfDay = DateTime(date.year, date.month, date.day);
  final endOfDay = DateTime(date.year, date.month, date.day + 1);
  return (database.select(database.task)
        ..where(
          (t) =>
              t.isDeleted.equals(false) &
              t.lastModified.isBiggerOrEqualValue(startOfDay) &
              t.lastModified.isSmallerThanValue(endOfDay),
        ))
      .watch()
      .map((rows) => rows.length);
});

final projectCountForDateProvider =
    StreamProvider.family<int, DateTime>((ref, date) {
  final database = ref.watch(databaseProvider);
  final startOfDay = DateTime(date.year, date.month, date.day);
  final endOfDay = DateTime(date.year, date.month, date.day + 1);
  return (database.select(database.project)
        ..where(
          (p) =>
              p.isDeleted.equals(false) &
              p.lastModified.isBiggerOrEqualValue(startOfDay) &
              p.lastModified.isSmallerThanValue(endOfDay),
        ))
      .watch()
      .map((rows) => rows.length);
});
