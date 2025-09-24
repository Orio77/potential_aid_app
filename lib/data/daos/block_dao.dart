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

  Future<void> assignTaskToBlock(int blockId, int taskId) async {
    await into(blockTask).insert(
      BlockTaskCompanion(blockId: Value(blockId), taskId: Value(taskId)),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> assignTasksToBlock(int blockId, List<int> taskIds) async {
    if (taskIds.isEmpty) return;

    await batch((batch) {
      for (final taskId in taskIds) {
        batch.insert(
          blockTask,
          BlockTaskCompanion(blockId: Value(blockId), taskId: Value(taskId)),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  Future<void> removeTaskFromBlock(int blockId, int taskId) async {
    await (delete(blockTask)..where(
          (bt) => (bt.blockId.equals(blockId) & bt.taskId.equals(taskId)),
        ))
        .go();
  }

  Future<List<TaskData>> getTasksForBlock(int blockId) async {
    final query = select(task).join([
      innerJoin(blockTask, blockTask.taskId.equalsExp(task.id)),
    ])..where(blockTask.blockId.equals(blockId));

    final rows = await query.get();
    return rows.map((row) => row.readTable(task)).toList();
  }

  Future<List<BlockData>> getBlocksForTask(int taskId) async {
    final query = select(block).join([
      innerJoin(blockTask, blockTask.blockId.equalsExp(block.id)),
    ])..where(blockTask.taskId.equals(taskId));

    final rows = await query.get();
    return rows.map((row) => row.readTable(block)).toList();
  }

  Future<BlockData?> getBlockById(int blockId) async {
    final query = select(block)..where((b) => b.id.equals(blockId));

    return await query.getSingleOrNull();
  }

  Future<List<BlockWithTasks>> getBlocksWithTasks(DateTime date) async {
    // Normalize date to start of day to handle timezone differences
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query =
        select(block).join([
            leftOuterJoin(blockTask, blockTask.blockId.equalsExp(block.id)),
            leftOuterJoin(task, task.id.equalsExp(blockTask.taskId)),
          ])
          ..where(
            block.dayLocal.isBiggerOrEqualValue(startOfDay) &
                block.dayLocal.isSmallerThanValue(endOfDay),
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

      if (taskData != null) {
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
      if (taskData != null) {
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
      BlockCompletionCompanion.insert(
        blockId: blockId,
        count: minutes,
        completedAt: completedAt,
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
}
