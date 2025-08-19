import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/tables/task.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Task])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.attachedDatabase);

  Future<List<TaskData>> searchTasks({
    required String query,
    int? limit,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final selectQuery = select(task)
      ..where((t) => t.name.lower().like('${q.toLowerCase()}%'));

    if (limit != null) {
      selectQuery.limit(limit);
    }

    return selectQuery.get();
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
    final taskData = TaskCompanion.insert(
      name: name,
      projectId: Value(projectId),
      deadline: Value(deadline),
      unit: Value(unit ?? ''),
      startPoint: Value(startPoint ?? 0),
      current: Value(current ?? 0),
      endGoal: Value(endGoal ?? 1),
    );

    final query = into(task).insert(taskData);

    return await query;
  }

  Future<List<TaskData>> getTasksByProject(int projectId) async {
    final query = select(task)
      ..where((task) => task.projectId.equals(projectId));

    return await query.get();
  }
}
