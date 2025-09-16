import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/tables/task.dart';
import 'package:potential_aid_app/data/tables/task_completion.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Task, TaskCompletion])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  Future<TaskData> getTask(int taskId) async {
    return await (select(task)..where((t) => t.id.equals(taskId))).getSingle();
  }

  Future<TaskData?> getParentTask(int taskId) async {
    final task = await getTask(taskId);
    return task.parentTaskId != null ? getTask(task.parentTaskId!) : null;
  }

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
    int? parentTaskId,
    int? depth,
    int? orderIndex,
  ]) async {
    final taskData = TaskCompanion.insert(
      name: name,
      projectId: projectId,
      deadline: Value(deadline),
      unit: Value(unit ?? ''),
      startPoint: Value(startPoint ?? 0),
      current: Value(current ?? 0),
      endGoal: Value(endGoal ?? 1),
      parentTaskId: Value(parentTaskId),
      depth: Value(depth ?? 0),
      orderIndex: Value(orderIndex ?? 0),
    );

    final query = into(task).insert(taskData);

    return await query;
  }

  Future<List<TaskData>> getTasksByProject(int projectId) async {
    final query = select(task)
      ..where((task) => task.projectId.equals(projectId))
      ..orderBy([
        (task) => OrderingTerm(expression: task.depth),
        (task) => OrderingTerm(expression: task.orderIndex),
      ]);

    return await query.get();
  }

  Future<int> completeTask(int taskId, int count, DateTime completedAt) async {
    if (count < 0) throw ArgumentError('Count must not be negative');

    return await transaction(() async {
      final taskData = await (select(
        task,
      )..where((task) => task.id.equals(taskId))).getSingle();

      bool completed = taskData.current + count >= taskData.endGoal;

      final completionId = await into(db.taskCompletion).insert(
        TaskCompletionCompanion.insert(
          taskId: taskId,
          count: count,
          completedAt: completedAt,
        ),
      );

      await (update(task)..where((task) => task.id.equals(taskId))).write(
        TaskCompanion(
          isCompleted: Value(completed),
          current: Value(taskData.current + count),
          completedAt: Value(completed ? completedAt : null),
        ),
      );

      return completionId;
    });
  }

  Future<List<TaskData>> getSubtasks(int taskId) async {
    return await (select(
      task,
    )..where((t) => t.parentTaskId.equals(taskId))).get();
  }
}
