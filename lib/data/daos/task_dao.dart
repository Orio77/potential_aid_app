import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/tables/task.dart';
import 'package:potential_aid_app/data/tables/task_completion.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Task, TaskCompletion])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  // Sync helper methods
  TaskCompanion _withSyncFields(TaskCompanion companion) {
    return companion.copyWith(
      lastModified: Value(DateTime.now()),
      needsSync: Value(true),
      version: Value(
        (companion.version.present ? companion.version.value : 1) + 1,
      ),
    );
  }

  TaskCompanion _markForDeletion(int version) {
    return TaskCompanion(
      isDeleted: Value(true),
      needsSync: Value(true),
      lastModified: Value(DateTime.now()),
      version: Value(version + 1),
    );
  }

  Future<TaskData> getTaskById(int taskId) async {
    return await (select(task)..where((t) => t.id.equals(taskId))).getSingle();
  }

  Future<TaskData?> getParentTask(int taskId) async {
    final task = await getTaskById(taskId);
    return task.parentTaskId != null ? getTaskById(task.parentTaskId!) : null;
  }

  Future<List<TaskData>> getAllTasks([
    List<Expression<bool> Function($TaskTable)>? predicates,
  ]) {
    final query = select(task);

    if (predicates != null && predicates.isNotEmpty) {
      for (final pred in predicates) {
        query.where(pred);
      }
    }

    return query.get();
  }

  Future<List<TaskData>> searchTasks({
    required String query,
    int? limit,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final selectQuery = select(task)
      ..where((t) => t.name.lower().contains('${q.toLowerCase()}%'));

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
    final taskData = _withSyncFields(
      TaskCompanion.insert(
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
        lastModified: DateTime.now(),
      ),
    );

    return await into(task).insert(taskData);
  }

  Future<int> updateTask(int taskId, TaskCompanion updates) async {
    final syncAwareUpdates = _withSyncFields(updates);
    return await (update(
      task,
    )..where((t) => t.id.equals(taskId))).write(syncAwareUpdates);
  }

  Future<void> deleteTask(int taskId) async {
    // Get current version for soft delete
    final currentTask = await getTaskById(taskId);
    final deleteCompanion = _markForDeletion(currentTask.version);

    await (update(
      task,
    )..where((t) => t.id.equals(taskId))).write(deleteCompanion);
  }

  Future<List<TaskData>> getTasksByProject(int projectId) async {
    final query = select(task)
      ..where((task) => task.projectId.equals(projectId))
      ..where((task) => task.isCompleted.equals(false))
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

      if (completed) {
        await _completeAllSubtasks(taskId, completedAt);
      }

      final completionId = await into(db.taskCompletion).insert(
        TaskCompletionCompanion.insert(
          taskId: taskId,
          count: count,
          completedAt: completedAt,
          lastModified: DateTime.now(),
          needsSync: Value(true),
          version: Value(1),
        ),
      );

      await (update(task)..where((task) => task.id.equals(taskId))).write(
        _withSyncFields(
          TaskCompanion(
            isCompleted: Value(completed),
            current: Value(taskData.current + count),
            completedAt: Value(completed ? completedAt : null),
          ),
        ),
      );

      return completionId;
    });
  }

  Future<void> _completeAllSubtasks(int taskId, DateTime completedAt) async {
    final incompleteSubtasks = await getAllDescendantsRecursive(
      taskId,
    ).then((subtasks) => subtasks.where((s) => !s.isCompleted).toList());

    if (incompleteSubtasks.isEmpty) return;

    await batch((batch) {
      for (final subtask in incompleteSubtasks) {
        batch.insert(
          db.taskCompletion,
          TaskCompletionCompanion.insert(
            taskId: subtask.id,
            count: subtask.endGoal - subtask.current,
            completedAt: completedAt,
            lastModified: DateTime.now(),
            needsSync: Value(true),
            version: Value(1),
          ),
        );
      }
    });

    await batch((batch) {
      for (final subtask in incompleteSubtasks) {
        batch.update(
          task,
          _withSyncFields(
            TaskCompanion(
              isCompleted: Value(true),
              current: Value(subtask.endGoal),
              completedAt: Value(completedAt),
            ),
          ),
          where: (t) => t.id.equals(subtask.id),
        );
      }
    });
  }

  Future<List<TaskCompletionData>> getTaskCompletionsForDate(
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await (select(taskCompletion)..where(
          (tc) =>
              tc.completedAt.isBiggerOrEqualValue(startOfDay) &
              tc.completedAt.isSmallerOrEqualValue(endOfDay),
        ))
        .get();
  }

  Future<List<TaskData>> getSubtasks(
    int taskId,
    List<Expression<bool> Function($TaskTable)>? predicates,
  ) async {
    final query = select(task)..where((t) => t.parentTaskId.equals(taskId));

    if (predicates != null && predicates.isNotEmpty) {
      for (final pred in predicates) {
        query.where(pred);
      }
    }

    // Order by order_index to maintain proper subtask ordering
    query.orderBy([(t) => OrderingTerm.asc(t.orderIndex)]);

    return await query.get();
  }

  Future<List<TaskData>> getAllDescendantsRecursive(int taskId) async {
    final query = '''
      WITH RECURSIVE task_descendants AS (
        -- Base case: direct children of the given task
        SELECT * FROM task WHERE parent_task_id = ?
        
        UNION ALL
        
        -- Recursive case: children of children
        SELECT t.* FROM task t
        INNER JOIN task_descendants td ON t.parent_task_id = td.id
      )
      SELECT * FROM task_descendants
      ORDER BY depth, order_index
    ''';

    final result = await customSelect(
      query,
      variables: [Variable.withInt(taskId)],
      readsFrom: {task},
    ).get();

    return result
        .map(
          (row) => TaskData.fromJson({
            'id': row.data['id'],
            'name': row.data['name'],
            'projectId': row.data['project_id'],
            'deadline': row.data['deadline'],
            'unit': row.data['unit'],
            'startPoint': row.data['start_point'],
            'current': row.data['current'],
            'endGoal': row.data['end_goal'],
            'parentTaskId': row.data['parent_task_id'],
            'depth': row.data['depth'],
            'orderIndex': row.data['order_index'],
            'isCompleted':
                (row.data['is_completed'] as int) ==
                1, // Convert SQLite int to bool
            'completedAt': row.data['completed_at'],
          }),
        )
        .toList();
  }
}
