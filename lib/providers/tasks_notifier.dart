import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/services/supabase_service.dart';

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

final _remoteTasksProvider = StreamProvider((ref) {
  return SupabaseService.instance.subscribeToTableChanges('task');
});

final _localUnsyncedTasksProvider = StreamProvider((ref) {
  final database = ref.watch(databaseProvider);
  return database.select(database.task).watch().map((tasks) {
    return tasks.where((t) => t.supabaseId == null && !t.isDeleted).toList();
  });
});

final taskCountForDateProvider = Provider.family<AsyncValue<int>, DateTime>((
  ref,
  date,
) {
  final remoteAsync = ref.watch(_remoteTasksProvider);
  final localAsync = ref.watch(_localUnsyncedTasksProvider);

  if (remoteAsync.isLoading || localAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (remoteAsync.hasError) {
    return AsyncValue.error(remoteAsync.error!, remoteAsync.stackTrace!);
  }

  final remoteRecords = remoteAsync.value ?? [];
  final localTasks = localAsync.value ?? [];

  final startOfDay = DateTime(date.year, date.month, date.day);
  final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  int count = 0;

  // Count remote tasks
  for (final task in remoteRecords) {
    if (task['is_deleted'] == true) continue;
    if (task['created_at'] == null) continue;

    final createdAt = DateTime.parse(task['created_at']).toLocal();
    if (createdAt.isAfter(startOfDay) && createdAt.isBefore(endOfDay)) {
      count++;
    }
  }

  // Count local unsynced tasks (using lastModified as proxy for createdAt)
  for (final task in localTasks) {
    if (task.lastModified.isAfter(startOfDay) &&
        task.lastModified.isBefore(endOfDay)) {
      count++;
    }
  }

  return AsyncValue.data(count);
});

final _remoteProjectsProvider = StreamProvider((ref) {
  return SupabaseService.instance.subscribeToTableChanges('project');
});

final _localUnsyncedProjectsProvider = StreamProvider((ref) {
  final database = ref.watch(databaseProvider);
  return database.select(database.project).watch().map((projects) {
    return projects.where((p) => p.supabaseId == null && !p.isDeleted).toList();
  });
});

final projectCountForDateProvider = Provider.family<AsyncValue<int>, DateTime>((
  ref,
  date,
) {
  final remoteAsync = ref.watch(_remoteProjectsProvider);
  final localAsync = ref.watch(_localUnsyncedProjectsProvider);

  if (remoteAsync.isLoading || localAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (remoteAsync.hasError) {
    return AsyncValue.error(remoteAsync.error!, remoteAsync.stackTrace!);
  }

  final remoteRecords = remoteAsync.value ?? [];
  final localProjects = localAsync.value ?? [];

  final startOfDay = DateTime(date.year, date.month, date.day);
  final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  int count = 0;

  // Count remote tasks
  for (final project in remoteRecords) {
    if (project['is_deleted'] == true) continue;
    if (project['created_at'] == null) continue;

    final createdAt = DateTime.parse(project['created_at']).toLocal();
    if (createdAt.isAfter(startOfDay) && createdAt.isBefore(endOfDay)) {
      count++;
    }
  }

  // Count local unsynced tasks (using lastModified as proxy for createdAt)
  for (final project in localProjects) {
    if (project.lastModified.isAfter(startOfDay) &&
        project.lastModified.isBefore(endOfDay)) {
      count++;
    }
  }

  return AsyncValue.data(count);
});
