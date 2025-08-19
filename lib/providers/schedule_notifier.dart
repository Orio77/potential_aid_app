import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/daos/database_completions.dart';
import 'package:potential_aid_app/data/tables/block.dart';
import 'package:potential_aid_app/providers/completion_notifier.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/data/database.dart';

class ScheduleNotifier extends StateNotifier<List<BlockWithTask>> {
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

    state = blocks;
  }

  Future<List<BlockWithTask>> _getBlocksWithTasks() async {
    final currentDate = _ref.read(dateNotifierProvider);
    final dateTime = currentDate.atMidnight().toDateTimeLocal();

    final blocksWithTasks = await _database.getBlocksWithTasksForDate(dateTime);

    return blocksWithTasks;
  }

  Future<void> editBlock(
    int blockId,
    int? startMinute,
    int? lengthMinutes,
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

    await (_database.update(
      _database.block,
    )..where((block) => block.id.equals(blockId))).write(
      BlockCompanion(
        startMinuteOfDay: Value(newStartMinute),
        lengthMinutes: Value(newLengthMinutes),
      ),
    );

    await _loadScheduleForCurrentDate();
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

    await _loadScheduleForCurrentDate();
  }

  Future<void> addBlock(int startMinute, int lengthMinutes, int taskId) async {
    final currentDate = _ref.read(dateNotifierProvider);
    final dateTime = currentDate.atMidnight().toDateTimeLocal();

    BlockCompanion block = BlockCompanion.insert(
      taskId: taskId,
      dayLocal: dateTime,
      startMinuteOfDay: startMinute,
      lengthMinutes: lengthMinutes,
    );

    await _database.into(_database.block).insert(block);
    await _loadScheduleForCurrentDate();
  }

  Future<void> removeTask(int blockId) async {
    // Delete the block (cascade will automatically delete task completions)
    await (_database.delete(
      _database.block,
    )..where((block) => block.id.equals(blockId))).go();

    // Invalidate the completion provider for this block
    _ref.invalidate(blockCompletionProvider(blockId));

    await _loadScheduleForCurrentDate();
  }

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    final blocks = await _getBlocksWithTasks();

    // Handle edge cases
    if (oldIndex == newIndex ||
        oldIndex >= blocks.length ||
        newIndex > blocks.length ||
        oldIndex < 0 ||
        newIndex < 0) {
      return;
    }

    final first = blocks[oldIndex];
    final second = blocks[newIndex];

    // Get the completion percentage directly from the database
    final firstCompletionPercentage = await _database
        .getBlockCompletionPercentage(first.block.id);
    final secondCompletionPercentage = await _database
        .getBlockCompletionPercentage(second.block.id);

    final anyCompleted =
        firstCompletionPercentage > 0 || secondCompletionPercentage > 0;

    if (anyCompleted) {
      return;
    }

    // Adjust newIndex for Flutter's ReorderableListView behavior
    // When moving down, Flutter gives us newIndex as the position after insertion
    if (newIndex > oldIndex) {
      newIndex--;
    }

    // If after adjustment they're the same, no reordering needed
    if (oldIndex == newIndex) {
      return;
    }

    // Create a copy of the blocks list and reorder it
    final reorderedBlocks = List<BlockWithTask>.from(blocks);
    final movedBlock = reorderedBlocks.removeAt(oldIndex);
    reorderedBlocks.insert(newIndex, movedBlock);

    // Update the database with new start times based on the new order
    await _database.transaction(() async {
      for (int i = 0; i < reorderedBlocks.length; i++) {
        final block = reorderedBlocks[i];
        final originalBlock = blocks[i];

        // Only update if the start time actually changed
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

  Future<void> addTaskCompletion(int blockId, int minutesCompleted) async {
    final currentDate = _ref.read(dateNotifierProvider);
    final dateTime = currentDate.atMidnight().toDateTimeLocal();

    final completion = TaskCompletionCompanion.insert(
      blockId: blockId,
      count: minutesCompleted,
      completedAt: dateTime,
    );

    await _database.into(_database.taskCompletion).insert(completion);

    // Invalidate the completion provider for this specific block to refresh the UI
    _ref.invalidate(blockCompletionProvider(blockId));
  }

  Future<ProjectData?> getProjectData(String name) async {
    return await _database.projectDao.getByName(name);
  }
}

final scheduleNotifierProvider =
    StateNotifierProvider<ScheduleNotifier, List<BlockWithTask>>((ref) {
      final database = ref.watch(databaseProvider);
      return ScheduleNotifier(database, ref);
    });
