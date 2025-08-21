import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/daos/database_completions.dart';
import 'package:potential_aid_app/data/tables/block.dart';
import 'package:potential_aid_app/providers/completion_notifier.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/data/database.dart';

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
    final blocks = await _getBlocksWithTasks();

    state = blocks.map((b) => b.block.id).toList();
  }

  Future<List<BlockWithTasks>> _getBlocksWithTasks() async {
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
  ) async {
    BlockData block = await (_database.select(
      _database.block,
    )..where((block) => block.id.equals(blockId))).getSingle();

    final newStartMinute = (startMinute == null || startMinute <= 0)
        ? block.startMinuteOfDay
        : startMinute;
    final newLengthMinutes = (lengthMinutes == null || lengthMinutes <= 0)
        ? block.lengthMinutes
        : lengthMinutes;
    final newProjectId = (projectId == null || projectId < 0)
        ? block.projectId
        : projectId;

    await (_database.update(
      _database.block,
    )..where((block) => block.id.equals(blockId))).write(
      BlockCompanion(
        startMinuteOfDay: Value(newStartMinute),
        lengthMinutes: Value(newLengthMinutes),
        projectId: Value(newProjectId),
      ),
    );
  }

  Future<void> editTask(int taskId, String? taskName) async {
    TaskData task = await (_database.select(
      _database.task,
    )..where((task) => task.id.equals(taskId))).getSingle();

    final newTaskName = (taskName == null || taskName.trim().isEmpty)
        ? task.name
        : taskName;

    await (_database.update(_database.task)
          ..where((task) => task.id.equals(taskId)))
        .write(TaskCompanion(name: Value(newTaskName)));
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
    );

    final blockId = await _database.into(_database.block).insert(block);
    await _loadScheduleForCurrentDate();
    return blockId;
  }

  Future<void> removeBlock(int blockId) async {
    await (_database.delete(
      _database.block,
    )..where((block) => block.id.equals(blockId))).go();

    _ref.invalidate(blockCompletionProvider(blockId));

    await _loadScheduleForCurrentDate();
  }

  Future<void> reorderBlocks(int oldIndex, int newIndex) async {
    final blocks = await _getBlocksWithTasks();

    if (oldIndex == newIndex ||
        oldIndex >= blocks.length ||
        newIndex > blocks.length ||
        oldIndex < 0 ||
        newIndex < 0) {
      return;
    }

    final first = blocks[oldIndex];
    final second = blocks[newIndex];
    final firstCompletionPercentage = await _database
        .getBlockCompletionPercentage(first.block.id);
    final secondCompletionPercentage = await _database
        .getBlockCompletionPercentage(second.block.id);

    final anyCompleted =
        firstCompletionPercentage > 0 || secondCompletionPercentage > 0;

    if (anyCompleted || oldIndex == newIndex) {
      return;
    }
    if (newIndex > oldIndex) {
      newIndex--;
    }

    final reorderedBlocks = List<BlockWithTasks>.from(blocks);
    final movedBlock = reorderedBlocks.removeAt(oldIndex);
    reorderedBlocks.insert(newIndex, movedBlock);

    await _database.transaction(() async {
      for (int i = 0; i < reorderedBlocks.length; i++) {
        final block = reorderedBlocks[i];
        final originalBlock = blocks[i];

        if (block.block.id != originalBlock.block.id) {
          await (_database.update(
            _database.block,
          )..where((b) => b.id.equals(block.block.id))).write(
            BlockCompanion(
              startMinuteOfDay: Value(originalBlock.block.startMinuteOfDay),
            ),
          );
        }
      }
    });

    await _loadScheduleForCurrentDate();
  }

  Future<void> assignTasksToBlock(int blockId, List<int> taskIds) async {
    await _database.blockDao.assignTasksToBlock(blockId, taskIds);
  }

  Future<void> addTaskCompletion(int blockId, int minutesCompleted) async {
    final currentDate = _ref.read(dateNotifierProvider);
    final dateTime = currentDate.atMidnight().toDateTimeLocal();

    final completion = TaskCompletionCompanion.insert(
      blockId: blockId,
      count: minutesCompleted,
      completedAt: dateTime,
    );

    await _database.into(_database.taskCompletion).insert(completion);

    _ref.invalidate(blockCompletionProvider(blockId));
  }
}

final scheduleNotifierProvider =
    StateNotifierProvider<ScheduleNotifier, List<int>>((ref) {
      final database = ref.watch(databaseProvider);
      return ScheduleNotifier(database, ref);
    });
