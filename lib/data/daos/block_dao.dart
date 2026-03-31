import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/tables/block.dart';
import 'package:potential_aid_app/data/tables/block_completion.dart';
import 'package:potential_aid_app/data/tables/block_task.dart';
import 'package:potential_aid_app/data/tables/task.dart';

part 'block_dao.g.dart';

@DriftAccessor(tables: [Block, BlockTask, Task, BlockCompletion])
class BlockDao extends DatabaseAccessor<AppDatabase> with _$BlockDaoMixin {
  BlockDao(super.attachedDatabase);

  BlockCompanion _withSyncFieldsB(BlockCompanion companion) {
    return companion.copyWith(
      lastModified: Value(DateTime.now()),
      needsSync: Value(true),
      version: Value(
        (companion.version.present ? companion.version.value : 1) + 1,
      ),
    );
  }

  // Sync helper methods
  BlockCompletionCompanion _withSyncFieldsBC(
    BlockCompletionCompanion companion,
  ) {
    return companion.copyWith(
      lastModified: Value(DateTime.now()),
      needsSync: Value(true),
      version: Value(
        (companion.version.present ? companion.version.value : 1) + 1,
      ),
    );
  }

  BlockCompanion _markBlockForDeletion(int version) {
    return BlockCompanion(
      isDeleted: Value(true),
      needsSync: Value(true),
      lastModified: Value(DateTime.now()),
      version: Value(version + 1),
    );
  }

  BlockTaskCompanion _markBlockTaskForDeletion(int version) {
    return BlockTaskCompanion(
      isDeleted: Value(true),
      needsSync: Value(true),
      lastModified: Value(DateTime.now()),
      version: Value(version + 1),
    );
  }

  Future<int> addBlock(BlockCompanion companion) async {
    return await into(block).insert(
      companion.copyWith(
        lastModified: Value(DateTime.now()),
        needsSync: Value(true),
        version: Value(1),
      ),
    );
  }

  Future<void> addBlockTask(BlockTaskCompanion companion) async {
    final existing =
        await (select(blockTask)..where(
              (bt) =>
                  bt.blockId.equals(companion.blockId.value) &
                  bt.taskId.equals(companion.taskId.value),
            ))
            .getSingleOrNull();

    if (existing != null) {
      await (update(blockTask)..where(
            (bt) =>
                bt.blockId.equals(companion.blockId.value) &
                bt.taskId.equals(companion.taskId.value),
          ))
          .write(
            BlockTaskCompanion(
              isDeleted: const Value(false),
              needsSync: const Value(true),
              lastModified: Value(DateTime.now()),
              version: Value(existing.version + 1),
            ),
          );
    } else {
      await into(blockTask).insert(
        companion.copyWith(
          lastModified: Value(DateTime.now()),
          needsSync: Value(true),
          version: Value(1),
          isDeleted: Value(false),
        ),
      );
    }
  }

  Future<void> assignTaskToBlock(int blockId, int taskId) async {
    final existing =
        await (select(blockTask)..where(
              (bt) => bt.blockId.equals(blockId) & bt.taskId.equals(taskId),
            ))
            .getSingleOrNull();

    if (existing != null) {
      await (update(blockTask)..where(
            (bt) => bt.blockId.equals(blockId) & bt.taskId.equals(taskId),
          ))
          .write(
            BlockTaskCompanion(
              isDeleted: const Value(false),
              needsSync: const Value(true),
              lastModified: Value(DateTime.now()),
              version: Value(existing.version + 1),
            ),
          );
    } else {
      await into(blockTask).insert(
        BlockTaskCompanion(
          blockId: Value(blockId),
          taskId: Value(taskId),
          lastModified: Value(DateTime.now()),
          isDeleted: const Value(false),
          needsSync: const Value(true),
          version: const Value(1),
        ),
      );
    }
  }

  Future<void> assignTasksToBlock(int blockId, List<int> taskIds) async {
    if (taskIds.isEmpty) return;

    // Process sequentially to handle upsert correctly
    for (final taskId in taskIds) {
      await assignTaskToBlock(blockId, taskId);
    }
  }

  Future<void> removeTaskFromBlock(int blockId, int taskId) async {
    final currentBlockTask = await getBlockTaskById(blockId, taskId);
    if (currentBlockTask != null) {
      final deleteCompanion = _markBlockTaskForDeletion(
        currentBlockTask.version,
      );
      await (update(blockTask)..where(
            (bt) => (bt.blockId.equals(blockId) & bt.taskId.equals(taskId)),
          ))
          .write(deleteCompanion);
    }
  }

  Future<void> deleteBlock(int blockId) async {
    final currentBlock = await getBlockById(blockId);
    if (currentBlock != null) {
      final deleteCompanion = _markBlockForDeletion(currentBlock.version);
      await (update(
        block,
      )..where((b) => b.id.equals(blockId))).write(deleteCompanion);
    }
  }

  Future<void> deleteBlockTask(int blockId, int taskId) async {
    final currentBlockTask = await getBlockTaskById(blockId, taskId);
    if (currentBlockTask != null) {
      final deleteCompanion = _markBlockTaskForDeletion(
        currentBlockTask.version,
      );
      await (update(blockTask)..where(
            (bt) => (bt.blockId.equals(blockId) & bt.taskId.equals(taskId)),
          ))
          .write(deleteCompanion);
    }
  }

  Future<void> deleteBlockTaskByBlockId(int blockId) async {
    final currentBlockTasks = await getBlockTasksForBlock(blockId);
    for (final currentBlockTask in currentBlockTasks) {
      final deleteCompanion = _markBlockTaskForDeletion(
        currentBlockTask.version,
      );
      await (update(blockTask)..where(
            (bt) =>
                (bt.blockId.equals(blockId) &
                bt.taskId.equals(currentBlockTask.taskId)),
          ))
          .write(deleteCompanion);
    }
  }

  Future<int> updateBlock(int blockId, BlockCompanion updates) async {
    final syncAwareUpdates = _withSyncFieldsB(updates);
    return await (update(
      block,
    )..where((b) => b.id.equals(blockId))).write(syncAwareUpdates);
  }

  Future<List<TaskData>> getTasksForBlock(int blockId) async {
    final query = select(task).join([
      innerJoin(blockTask, blockTask.taskId.equalsExp(task.id)),
    ])..where(
      blockTask.blockId.equals(blockId) &
      blockTask.isDeleted.equals(false) &
      task.isDeleted.equals(false),
    );

    final rows = await query.get();
    return rows.map((row) => row.readTable(task)).toList();
  }

  Future<List<BlockData>> getBlocksForTask(int taskId) async {
    final query = select(block).join([
      innerJoin(blockTask, blockTask.blockId.equalsExp(block.id)),
    ])..where(
      blockTask.taskId.equals(taskId) &
      blockTask.isDeleted.equals(false) &
      block.isDeleted.equals(false),
    );

    final rows = await query.get();
    return rows.map((row) => row.readTable(block)).toList();
  }

  Future<BlockData?> getBlockById(int blockId) async {
    final query = select(block)..where((b) => b.id.equals(blockId));

    return await query.getSingleOrNull();
  }

  Future<BlockTaskData?> getBlockTaskById(int blockId, int taskId) async {
    final query = select(blockTask)
      ..where((bt) => (bt.blockId.equals(blockId) & bt.taskId.equals(taskId)));

    return await query.getSingleOrNull();
  }

  Future<List<BlockTaskData>> getBlockTasksForBlock(int blockId) async {
    final query = select(blockTask)
      ..where((bt) => bt.blockId.equals(blockId) & bt.isDeleted.equals(false));

    return await query.get();
  }

  Future<List<BlockWithTasks>> getBlocksWithTasks(DateTime date) async {
    // Normalize date to start of day to handle timezone differences
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query =
        select(block).join([
            leftOuterJoin(
              blockTask,
              blockTask.blockId.equalsExp(block.id) &
                  blockTask.isDeleted.equals(false),
            ),
            leftOuterJoin(task, task.id.equalsExp(blockTask.taskId)),
          ])
          ..where(
            block.dayLocal.isBiggerOrEqualValue(startOfDay) &
                block.dayLocal.isSmallerThanValue(endOfDay) &
                block.isDeleted.equals(false),
          )
          ..orderBy([OrderingTerm.asc(block.startMinuteOfDay)]);

    final rows = await query.get();

    final Map<int, BlockWithTasks> blockMap = {};

    for (final row in rows) {
      final blockData = row.readTable(block);
      final taskData = row.readTableOrNull(task);

      final blockWithTasks = blockMap.putIfAbsent(
        blockData.id,
        () => BlockWithTasks(block: blockData, tasks: []),
      );

      if (taskData != null && !taskData.isDeleted) {
        blockWithTasks.tasks!.add(taskData);
      }
    }

    return blockMap.values.toList();
  }

  Future<BlockWithTasks> getBlockWithTasks(int blockId) async {
    final query = select(block).join([
      leftOuterJoin(blockTask, blockTask.blockId.equalsExp(block.id)),
      leftOuterJoin(task, task.id.equalsExp(blockTask.taskId)),
    ])..where(block.id.equals(blockId));

    final rows = await query.get();

    if (rows.isEmpty) {
      throw StateError('Block with id $blockId not found');
    }

    final blockData = rows.first.readTable(block);
    final tasks = <TaskData>[];

    for (final row in rows) {
      final taskData = row.readTableOrNull(task);
      if (taskData != null && !taskData.isDeleted) {
        tasks.add(taskData);
      }
    }

    return BlockWithTasks(block: blockData, tasks: tasks);
  }

  Future<int> completeBlock(
    int blockId,
    int minutes,
    DateTime completedAt,
  ) async {
    if (minutes < 0) throw ArgumentError('Count must not be negative');

    final completionId = await into(db.blockCompletion).insert(
      _withSyncFieldsBC(
        BlockCompletionCompanion.insert(
          blockId: blockId,
          count: minutes,
          completedAt: completedAt,
          lastModified: DateTime.now(),
        ),
      ),
    );

    return completionId;
  }

  Future<List<BlockCompletionData>> getBlockCompletionsForDate(
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = select(blockCompletion)
      ..where(
        (bc) =>
            bc.completedAt.isBiggerOrEqualValue(startOfDay) &
            bc.completedAt.isSmallerThanValue(endOfDay),
      );

    return await query.get();
  }

  Future<BlockCompletionData?> getCompletionForBlock(int blockId) async {
    return await (select(
      blockCompletion,
    )..where((bc) => bc.blockId.equals(blockId))).getSingleOrNull();
  }

  Future<double?> getBlockCompletionPercentage(int blockId) async {
    // check if all tasks completed
    final blockTask = await getBlockWithTasks(blockId);
    final blockCompletion = await getCompletionForBlock(blockId);

    if (blockCompletion == null) {
      return null;
    }

    bool allTasksCompleted = true;
    if (blockTask.tasks != null && blockTask.tasks!.isNotEmpty) {
      for (final task in blockTask.tasks!) {
        bool taskCompleted = task.current >= task.endGoal;
        allTasksCompleted = allTasksCompleted && taskCompleted;
      }
    } else {
      allTasksCompleted = false;
    }

    if (allTasksCompleted) {
      return 100.0;
    } else {
      final percentage =
          (blockCompletion.count / blockTask.block.lengthMinutes * 100)
              .toDouble();
      return percentage;
    }
  }
}
