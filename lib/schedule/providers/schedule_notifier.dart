import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/tables/block.dart';
import 'package:potential_aid_app/schedule/providers/block_with_tasks_notifier.dart';
import 'package:potential_aid_app/schedule/providers/completion_notifier.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:potential_aid_app/stats/providers/stats_provider.dart';
import 'package:time_machine/time_machine.dart';

class ScheduleNotifier extends StateNotifier<List<int>> {
  final AppDatabase _database;
  final Ref _ref;
  late final ProviderSubscription _dateSubscription;

  ScheduleNotifier(this._database, this._ref) : super([]) {
    _dateSubscription = _ref.listen(dateNotifierProvider, (previous, next) {
      _loadScheduleForCurrentDate();
    });
    _loadScheduleForCurrentDate();
  }

  @override
  void dispose() {
    _dateSubscription.close();
    super.dispose();
  }

  Future<void> _loadScheduleForCurrentDate() async {
    final blocks = await getBlocksWithTasks();

    if (mounted) {
      state = blocks.map((b) => b.block.id).toList();
    }
  }

  Future<List<BlockWithTasks>> getBlocksWithTasks() async {
    final currentDate = _ref.read(dateNotifierProvider);
    final dateTime = currentDate.atMidnight().toDateTimeLocal();

    final blocksWithTasks = await _database.blockDao.getBlocksWithTasks(
      dateTime,
    );

    return blocksWithTasks;
  }

  Future<BlockData?> getBlockById(int blockId) async {
    return await _database.blockDao.getBlockById(blockId);
  }

  Future<void> editBlock(
    int blockId,
    int? startMinute,
    int? lengthMinutes,
    int? projectId,
    List<int>? taskIds,
  ) async {
    BlockData? block = await _database.blockDao.getBlockById(blockId);
    if (block == null) {
      return;
    }

    List<BlockTaskData> initialTasks = await _database.blockDao
        .getBlockTasksForBlock(blockId);
    // Filter out deleted tasks to ensure we correctly identify tasks to add/remove
    initialTasks = initialTasks.where((bt) => !bt.isDeleted).toList();
    List<int> initialTaskIds = initialTasks.map((bt) => bt.taskId).toList();

    final newStartMinute = (startMinute == null || startMinute <= 0)
        ? block.startMinuteOfDay
        : startMinute;
    final newLengthMinutes = (lengthMinutes == null || lengthMinutes <= 0)
        ? block.lengthMinutes
        : lengthMinutes;
    final newProjectId = (projectId == null || projectId < 0)
        ? block.projectId
        : projectId;
    final newTaskIds = taskIds ?? initialTaskIds;

    await _database.transaction(() async {
      await _database.blockDao.updateBlock(
        blockId,
        BlockCompanion(
          startMinuteOfDay: Value(newStartMinute),
          lengthMinutes: Value(newLengthMinutes),
          projectId: Value(newProjectId),
        ),
      );

      final tasksToRemove = initialTaskIds
          .where((id) => !newTaskIds.contains(id))
          .toList();
      final tasksToAdd = newTaskIds
          .where((id) => !initialTaskIds.contains(id))
          .toList();

      for (final taskId in tasksToRemove) {
        await _database.blockDao.removeTaskFromBlock(blockId, taskId);
      }

      for (final taskId in tasksToAdd) {
        await _database.blockDao.addBlockTask(
          BlockTaskCompanion(blockId: Value(blockId), taskId: Value(taskId)),
        );
      }
    });

    _ref.invalidate(blockTasksNotifier(blockId));
    await _loadScheduleForCurrentDate();
  }

  Future<void> editTask(int taskId, String? taskName) async {
    TaskData task = await _database.taskDao.getTaskById(taskId);

    final newTaskName = (taskName == null || taskName.trim().isEmpty)
        ? task.name
        : taskName;

    await _database.taskDao.updateTask(
      taskId,
      TaskCompanion(name: Value(newTaskName)),
    );
  }

  Future<int> addBlock(
    int startMinute,
    int lengthMinutes,
    int projectId,
  ) async {
    final currentDate = _ref.read(dateNotifierProvider);
    final dateTime = currentDate.atMidnight().toDateTimeLocal();

    BlockCompanion block = BlockCompanion.insert(
      projectId: projectId,
      dayLocal: dateTime,
      startMinuteOfDay: startMinute,
      lengthMinutes: lengthMinutes,
      lastModified: DateTime.now(),
    );

    final blockId = await _database.blockDao.addBlock(block);

    await _loadScheduleForCurrentDate();
    return blockId;
  }

  Future<void> removeBlock(int blockId) async {
    await _database.blockDao.deleteBlock(blockId);

    _ref.invalidate(blockCompletionPercentageProvider(blockId));

    await _loadScheduleForCurrentDate();
  }

  Future<void> reorderBlocks(int oldIndex, int newIndex) async {
    final blocks = await getBlocksWithTasks();

    // Check if any of the blocks are completed - prevent reordering if so
    final first = blocks[oldIndex];
    final firstCompletionPercentage = await _database.blockDao
        .getBlockCompletionPercentage(first.block.id);
    final second = blocks[newIndex];
    final secondCompletionPercentage = await _database.blockDao
        .getBlockCompletionPercentage(second.block.id);

    if (firstCompletionPercentage != null ||
        secondCompletionPercentage != null) {
      return;
    }

    // Adjust newIndex for the removal (same as working categories method)
    if (newIndex > oldIndex) {
      newIndex--;
    }

    // Reorder the blocks list
    final reorderedBlocks = List<BlockWithTasks>.from(blocks);
    final movedBlock = reorderedBlocks.removeAt(oldIndex);
    reorderedBlocks.insert(newIndex, movedBlock);

    // Update database with new start times based on reordered sequence
    try {
      // Extract the original start times before reordering
      final originalStartTimes =
          blocks.map((b) => b.block.startMinuteOfDay).toList()
            ..sort(); // Sort to maintain chronological order

      await _updateBlockTimesInDatabase(reorderedBlocks, originalStartTimes);

      // Invalidate all block providers to refresh the UI with new start times
      for (final block in reorderedBlocks) {
        _ref.invalidate(blockTasksNotifier(block.block.id));
      }

      await _loadScheduleForCurrentDate();
    } catch (e) {
      // If database update fails, reload from database to ensure consistency
      await _loadScheduleForCurrentDate();
    }
  }

  Future<void> _updateBlockTimesInDatabase(
    List<BlockWithTasks> orderedBlocks,
    List<int> originalStartTimes,
  ) async {
    // Use a transaction to ensure all updates happen atomically
    await _database.transaction(() async {
      for (int i = 0; i < orderedBlocks.length; i++) {
        final block = orderedBlocks[i];

        final bc = BlockCompanion(
          startMinuteOfDay: Value(originalStartTimes[i]),
        );

        await _database.blockDao.updateBlock(block.block.id, bc);
      }
    });
  }

  Future<void> assignTasksToBlock(int blockId, List<int> taskIds) async {
    await _database.blockDao.assignTasksToBlock(blockId, taskIds);
  }

  Future<int> addTaskCompletion(int taskId, int completedCount) async {
    final currentDate = _ref.read(dateNotifierProvider);
    final dateTime = currentDate.atMidnight().toDateTimeLocal();

    final result = await _database.taskDao.completeTask(
      taskId,
      completedCount,
      dateTime,
    );

    final task = await _database.taskDao.getTaskById(taskId);
    _ref.invalidate(projectStatsNotifier(task.projectId));

    final monthYearDate = LocalDate.today();
    _ref.invalidate(
      taskCompletionMonthlyNotifier(
        TaskCompletionParams(
          monthYearDate: monthYearDate,
          projectId: task.projectId,
        ),
      ),
    );

    final projectData = await _database.projectDao.getProjectById(
      task.projectId,
    );

    if (projectData != null && task.unit == projectData.unit) {
      await _database.projectDao.addProjectCompletion(
        task.projectId,
        completedCount,
      );
      _ref.invalidate(projectProvider(task.projectId));
    }

    _ref.invalidate(projectTasksNotifier(task.projectId));

    return result;
  }

  Future<int> addBlockCompletion(int blockId, int minutesCompleted) async {
    final currentDate = _ref.read(dateNotifierProvider);
    final dateTime = currentDate.atMidnight().toDateTimeLocal();

    final completionId = await _database.blockDao.completeBlock(
      blockId,
      minutesCompleted,
      dateTime,
    );

    _ref.invalidate(blockCompletionPercentageProvider(blockId));

    final block = await _database.blockDao.getBlockById(blockId);
    if (block == null) {
      return completionId;
    }

    _ref.invalidate(projectStatsNotifier(block.projectId));

    final monthYearDate = LocalDate.today();
    _ref.invalidate(
      taskCompletionMonthlyNotifier(
        TaskCompletionParams(
          monthYearDate: monthYearDate,
          projectId: block.projectId,
        ),
      ),
    );

    return completionId;
  }

  Future<int> addProjectCompletion(int projectId, int completionCount) async {
    final res = await _database.projectDao.addProjectCompletion(
      projectId,
      completionCount,
    );

    _ref.invalidate(projectProvider(projectId));

    return res;
  }
}

final scheduleNotifierProvider =
    StateNotifierProvider<ScheduleNotifier, List<int>>((ref) {
      final database = ref.watch(databaseProvider);
      return ScheduleNotifier(database, ref);
    });
