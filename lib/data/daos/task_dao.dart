import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/tables/task.dart';
import 'package:potential_aid_app/data/tables/task_completion.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Task, TaskCompletion])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  // Sync helper methods
  //
  // [currentVersion] must be the row's current version as read from the DB
  // (or 0 for a brand-new insert so the row lands at version 1). Never rely
  // on [companion.version] — callers almost never set it, so the previous
  // implementation always produced version=2.
  TaskCompanion _withSyncFields(TaskCompanion companion, int currentVersion) {
    return companion.copyWith(
      lastModified: Value(DateTime.now()),
      needsSync: const Value(true),
      version: Value(currentVersion + 1),
    );
  }

  TaskCompanion _markForDeletion(int version) {
    return TaskCompanion(
      isDeleted: const Value(true),
      needsSync: const Value(true),
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
    query.where((t) => t.isDeleted.equals(false));

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
      ..where(
        (t) =>
            t.name.lower().contains('${q.toLowerCase()}%') &
            t.isDeleted.equals(false) &
            t.isCompleted.equals(false),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.depth)]);

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
      // Brand-new row: baseline 0 so helper writes version=1.
      0,
    );

    return await into(task).insert(taskData);
  }

  Future<int> updateTask(int taskId, TaskCompanion updates) async {
    return transaction(() async {
      final existing = await getTaskById(taskId);

      final nextEndGoal = updates.endGoal.present
          ? updates.endGoal.value
          : existing.endGoal;

      final forceComplete = updates.isCompleted.present &&
          updates.isCompleted.value == true &&
          !existing.isCompleted;

      var cappedCurrent = forceComplete
          ? nextEndGoal
          : (updates.current.present ? updates.current.value : existing.current);
      if (cappedCurrent > nextEndGoal) cappedCurrent = nextEndGoal;
      if (cappedCurrent < 0) cappedCurrent = 0;

      final progressDelta = cappedCurrent - existing.current;
      final completionTs = DateTime.now();

      if (progressDelta > 0) {
        await into(db.taskCompletion).insert(
          TaskCompletionCompanion.insert(
            taskId: taskId,
            count: progressDelta,
            completedAt: completionTs,
            lastModified: DateTime.now(),
            needsSync: const Value(true),
            version: const Value(1),
          ),
        );
      }

      final completed = cappedCurrent >= nextEndGoal;
      if (completed && !existing.isCompleted) {
        await _completeAllSubtasks(taskId, completionTs);
      }

      final nextCompletedAt = completed
          ? (existing.completedAt ?? completionTs)
          : null;

      final merged = updates.copyWith(
        current: Value(cappedCurrent),
        isCompleted: Value(completed),
        completedAt: Value(nextCompletedAt),
      );

      final syncAwareUpdates = _withSyncFields(merged, existing.version);
      return await (update(
        task,
      )..where((t) => t.id.equals(taskId))).write(syncAwareUpdates);
    });
  }

  Future<void> deleteTask(int taskId) async {
    await transaction(() async {
      final currentTask = await getTaskById(taskId);

      // Cascade soft-delete all descendants first
      final descendants = await getAllDescendantsRecursive(taskId);
      final allIds = <int>[taskId, ...descendants.map((d) => d.id)];

      if (descendants.isNotEmpty) {
        await batch((b) {
          for (final desc in descendants) {
            b.update(
              task,
              _markForDeletion(desc.version),
              where: (row) => row.id.equals(desc.id),
            );
          }
        });
      }

      await (update(task)..where((t) => t.id.equals(taskId))).write(
        _markForDeletion(currentTask.version),
      );

      // Soft-delete dependent rows so they're pushed to Supabase as deletes
      // before the local FK cascade has a chance to hard-delete them.
      await _softDeleteDependentsForTasks(allIds);
    });
  }

  /// Soft-deletes all non-deleted tasks belonging to [projectId] and their
  /// dependent rows (block_task links, task_completion). Called as part of
  /// project deletion to prevent orphaned rows on the remote DB.
  Future<void> softDeleteTasksByProject(int projectId) async {
    final tasks =
        await (select(task)..where(
              (t) => t.projectId.equals(projectId) & t.isDeleted.equals(false),
            ))
            .get();

    if (tasks.isEmpty) return;

    await batch((b) {
      for (final t in tasks) {
        b.update(
          task,
          _markForDeletion(t.version),
          where: (row) => row.id.equals(t.id),
        );
      }
    });

    await _softDeleteDependentsForTasks(tasks.map((t) => t.id).toList());
  }

  /// Marks every still-live block_task and task_completion row attached to
  /// any of [taskIds] as deleted+needsSync so they'll be pushed to Supabase
  /// instead of silently disappearing via the local FK cascade.
  Future<void> _softDeleteDependentsForTasks(List<int> taskIds) async {
    if (taskIds.isEmpty) return;

    final now = DateTime.now();

    final links =
        await (select(db.blockTask)..where(
              (bt) => bt.taskId.isIn(taskIds) & bt.isDeleted.equals(false),
            ))
            .get();
    if (links.isNotEmpty) {
      await batch((b) {
        for (final link in links) {
          b.update(
            db.blockTask,
            BlockTaskCompanion(
              isDeleted: const Value(true),
              needsSync: const Value(true),
              lastModified: Value(now),
              version: Value(link.version + 1),
            ),
            where: (bt) =>
                bt.blockId.equals(link.blockId) &
                bt.taskId.equals(link.taskId),
          );
        }
      });
    }

    final completions =
        await (select(db.taskCompletion)..where(
              (tc) => tc.taskId.isIn(taskIds) & tc.isDeleted.equals(false),
            ))
            .get();
    if (completions.isNotEmpty) {
      await batch((b) {
        for (final c in completions) {
          b.update(
            db.taskCompletion,
            TaskCompletionCompanion(
              isDeleted: const Value(true),
              needsSync: const Value(true),
              lastModified: Value(now),
              version: Value(c.version + 1),
            ),
            where: (tc) => tc.id.equals(c.id),
          );
        }
      });
    }
  }

  Future<List<TaskData>> getTasksByProject(int projectId) async {
    final query = select(task)
      ..where((task) => task.projectId.equals(projectId))
      ..where((task) => task.isCompleted.equals(false))
      ..where((task) => task.isDeleted.equals(false))
      ..orderBy([
        (task) => OrderingTerm(expression: task.depth),
        (task) => OrderingTerm(expression: task.orderIndex),
      ]);

    return await query.get();
  }

  /// All non-deleted, non-completed tasks for a project, sorted by orderIndex.
  Future<List<TaskData>> getAllTasksByProject(int projectId) async {
    final query = select(task)
      ..where((t) => t.projectId.equals(projectId))
      ..where((t) => t.isDeleted.equals(false))
      ..where((t) => t.isCompleted.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]);
    return await query.get();
  }

  Future<int> completeTask(int taskId, int count, DateTime completedAt) async {
    if (count < 0) throw ArgumentError('Count must not be negative');

    return await transaction(() async {
      final taskData = await (select(
        task,
      )..where((task) => task.id.equals(taskId))).getSingle();

      bool completed = taskData.current + count >= taskData.endGoal;

      if (completed && !taskData.isCompleted) {
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
            current: Value(completed
                ? taskData.endGoal
                : taskData.current + count),
            completedAt: Value(completed ? completedAt : null),
          ),
          taskData.version,
        ),
      );

      // If this task transitioned from not-completed to completed, roll up
      // one unit of progress to its parent (each completed subtask counts as
      // one unit toward its parent's goal).
      if (completed &&
          !taskData.isCompleted &&
          taskData.parentTaskId != null) {
        await _rollupCompletionToParent(
          taskData.parentTaskId!,
          completedAt,
        );
      }

      return completionId;
    });
  }

  /// Adds one unit of progress to [parentId] because a direct child just
  /// transitioned to completed. If the parent reaches its goal, its remaining
  /// incomplete descendants are cascaded to completed and the rollup continues
  /// up the chain.
  Future<void> _rollupCompletionToParent(
    int parentId,
    DateTime completedAt,
  ) async {
    final parent = await getTaskById(parentId);
    if (parent.isCompleted) return;

    final newCurrent = parent.current + 1;
    final willComplete = newCurrent >= parent.endGoal;

    if (willComplete) {
      await _completeAllSubtasks(parentId, completedAt);
    }

    await into(db.taskCompletion).insert(
      TaskCompletionCompanion.insert(
        taskId: parentId,
        count: 1,
        completedAt: completedAt,
        lastModified: DateTime.now(),
        needsSync: const Value(true),
        version: const Value(1),
      ),
    );

    await (update(task)..where((t) => t.id.equals(parentId))).write(
      _withSyncFields(
        TaskCompanion(
          isCompleted: Value(willComplete),
          current: Value(willComplete ? parent.endGoal : newCurrent),
          completedAt: Value(willComplete ? completedAt : null),
        ),
        parent.version,
      ),
    );

    if (willComplete && parent.parentTaskId != null) {
      await _rollupCompletionToParent(parent.parentTaskId!, completedAt);
    }
  }

  Future<void> _completeAllSubtasks(int taskId, DateTime completedAt) async {
    final incompleteSubtasks = await getAllDescendantsRecursive(
      taskId,
    ).then((subtasks) => subtasks.where((s) => !s.isCompleted).toList());

    if (incompleteSubtasks.isEmpty) return;

    await batch((b) {
      for (final subtask in incompleteSubtasks) {
        final remaining = subtask.endGoal - subtask.current;
        if (remaining > 0) {
          b.insert(
            db.taskCompletion,
            TaskCompletionCompanion.insert(
              taskId: subtask.id,
              count: remaining,
              completedAt: completedAt,
              lastModified: DateTime.now(),
              needsSync: const Value(true),
              version: const Value(1),
            ),
          );
        }
      }
    });

    await batch((b) {
      for (final subtask in incompleteSubtasks) {
        b.update(
          task,
          _withSyncFields(
            TaskCompanion(
              isCompleted: const Value(true),
              current: Value(subtask.endGoal),
              completedAt: Value(completedAt),
            ),
            subtask.version,
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

  // Get subtasks, one level down, with optional filtering predicates
  Future<List<TaskData>> getSubtasks(
    int taskId,
    List<Expression<bool> Function($TaskTable)>? predicates,
  ) async {
    final query = select(task)..where((t) => t.parentTaskId.equals(taskId));
    query.where((st) => st.isDeleted.equals(false));

    if (predicates != null && predicates.isNotEmpty) {
      for (final pred in predicates) {
        query.where(pred);
      }
    }

    // Order by order_index to maintain proper subtask ordering
    query.orderBy([(t) => OrderingTerm.asc(t.orderIndex)]);

    return await query.get();
  }

  Future<List<TaskData>> getFirstDepthTasksForProject(int projectId) async {
    final query = select(task)
      ..where((t) => t.projectId.equals(projectId))
      ..where((t) => t.parentTaskId.isNull())
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]);
    return query.get();
  }

  /// Marks every non-completed, non-deleted task in [projectId] as completed.
  /// Called when a project's current value reaches or exceeds its goal on edit.
  Future<void> completeAllTasksForProject(int projectId) async {
    final incompleteTasks = await getTasksByProject(projectId);
    if (incompleteTasks.isEmpty) return;

    final completedAt = DateTime.now();

    await batch((b) {
      for (final t in incompleteTasks) {
        final remaining = t.endGoal - t.current;
        if (remaining > 0) {
          b.insert(
            db.taskCompletion,
            TaskCompletionCompanion.insert(
              taskId: t.id,
              count: remaining,
              completedAt: completedAt,
              lastModified: DateTime.now(),
              needsSync: const Value(true),
              version: const Value(1),
            ),
          );
        }
      }
    });

    await batch((b) {
      for (final t in incompleteTasks) {
        b.update(
          task,
          _withSyncFields(
            TaskCompanion(
              isCompleted: const Value(true),
              current: Value(t.endGoal),
              completedAt: Value(completedAt),
            ),
            t.version,
          ),
          where: (row) => row.id.equals(t.id),
        );
      }
    });
  }

  Future<void> updateTaskProgress(int taskId, int newCurrent) async {
    return transaction(() async {
      final taskData = await getTaskById(taskId);
      final bool nowComplete = newCurrent >= taskData.endGoal;
      final actualCurrent = nowComplete ? taskData.endGoal : newCurrent;
      final completionTs = DateTime.now();
      final progressDelta = actualCurrent - taskData.current;

      if (progressDelta > 0) {
        await into(db.taskCompletion).insert(
          TaskCompletionCompanion.insert(
            taskId: taskId,
            count: progressDelta,
            completedAt: completionTs,
            lastModified: DateTime.now(),
            needsSync: const Value(true),
            version: const Value(1),
          ),
        );
      }

      if (nowComplete && !taskData.isCompleted) {
        await _completeAllSubtasks(taskId, completionTs);
      }

      await (update(task)..where((t) => t.id.equals(taskId))).write(
        _withSyncFields(
          TaskCompanion(
            current: Value(actualCurrent),
            isCompleted: Value(nowComplete || taskData.isCompleted),
            completedAt: Value(
              nowComplete && taskData.completedAt == null
                  ? completionTs
                  : taskData.completedAt,
            ),
          ),
          taskData.version,
        ),
      );
    });
  }

  // Recursive retrieval of all descendant tasks
  Future<List<TaskData>> getAllDescendantsRecursive(int taskId) async {
    final query = '''
      WITH RECURSIVE task_descendants AS (
        -- Base case: direct children of the given task
        SELECT * FROM task WHERE parent_task_id = ? AND is_deleted = 0

        UNION ALL

        -- Recursive case: children of children
        SELECT t.* FROM task t
        INNER JOIN task_descendants td ON t.parent_task_id = td.id
        WHERE t.is_deleted = 0
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
          (row) => TaskData(
            id: row.read<int>('id'),
            name: row.read<String>('name'),
            projectId: row.read<int>('project_id'),
            deadline: row.read<DateTime?>('deadline'),
            unit: row.read<String?>('unit'),
            startPoint: row.read<int?>('start_point'),
            current: row.read<int>('current'),
            endGoal: row.read<int>('end_goal'),
            parentTaskId: row.read<int?>('parent_task_id'),
            depth: row.read<int>('depth'),
            orderIndex: row.read<int>('order_index'),
            isCompleted: row.read<bool>('is_completed'),
            completedAt: row.read<DateTime?>('completed_at'),
            supabaseId: row.read<String?>('supabase_id'),
            lastModified: row.read<DateTime>('last_modified'),
            needsSync: row.read<bool>('needs_sync'),
            isDeleted: row.read<bool>('is_deleted'),
            version: row.read<int>('version'),
          ),
        )
        .toList();
  }
}
