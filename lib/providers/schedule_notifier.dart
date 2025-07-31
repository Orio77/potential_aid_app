import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/models/block.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/services/database.dart';

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

  // TODO Implement
  Future<void> editTask() async {}

  Future<void> addTask(
    String taskName,
    int startMinute,
    int lengthMinutes,
  ) async {
    final task = TaskCompanion.insert(
      name: taskName,
      estimatedMinutes: lengthMinutes,
    );

    final taskId = await _database.into(_database.task).insert(task);

    final currentDate = _ref.read(dateNotifierProvider);
    final dateTime = currentDate.atMidnight().toDateTimeLocal();

    final block = BlockCompanion.insert(
      taskId: taskId,
      dayLocal: dateTime,
      startMinuteOfDay: startMinute,
      lengthMinutes: lengthMinutes,
    );

    await _database.into(_database.block).insert(block);

    await _loadScheduleForCurrentDate();
  }

  Future<void> removeTask(int blockId) async {
    await (_database.delete(
      _database.block,
    )..where((block) => block.id.equals(blockId))).go();

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

  /// Add example tasks for testing the UI (WILL BE REMOVED)
  Future<void> addExampleTasks() async {
    final currentDate = _ref.read(dateNotifierProvider);
    final dateTime = currentDate.atMidnight().toDateTimeLocal();

    // Check if we already have tasks for today
    final existingBlocks = await _getBlocksWithTasks();
    if (existingBlocks.isNotEmpty) {
      return; // Don't add duplicates
    }

    final exampleTasks = [
      ('Morning Review', 8 * 60 + 35, 60), // 08:35, 1 hour
      ('Deep Work Session', 9 * 60 + 40, 90), // 09:40, 1.5 hours
      ('Team Meeting', 11 * 60 + 15, 45), // 11:15, 45 minutes
      ('Lunch Break', 12 * 60 + 5, 60), // 12:05, 1 hour
      ('Project Planning', 13 * 60 + 10, 120), // 13:10, 2 hours
      ('Code Review', 15 * 60 + 15, 30), // 15:15, 30 minutes
    ];

    await _database.transaction(() async {
      for (final (taskName, startMinute, lengthMinutes) in exampleTasks) {
        // Create task
        final task = TaskCompanion.insert(
          name: taskName,
          estimatedMinutes: lengthMinutes,
        );
        final taskId = await _database.into(_database.task).insert(task);

        // Create block
        final block = BlockCompanion.insert(
          taskId: taskId,
          dayLocal: dateTime,
          startMinuteOfDay: startMinute,
          lengthMinutes: lengthMinutes,
        );
        await _database.into(_database.block).insert(block);
      }
    });

    await _loadScheduleForCurrentDate();
  }

  /// Clear all tasks for the current day (WILL BE REMOVED)
  Future<void> clearTodaysTasks() async {
    final currentDate = _ref.read(dateNotifierProvider);
    final dateTime = currentDate.atMidnight().toDateTimeLocal();

    // Get all blocks for today
    final blocksToDelete = await _getBlocksWithTasks();

    if (blocksToDelete.isEmpty) {
      return; // Nothing to delete
    }

    await _database.transaction(() async {
      // Delete all blocks for today
      await (_database.delete(
        _database.block,
      )..where((block) => block.dayLocal.equals(dateTime))).go();

      // Optionally delete orphaned tasks (tasks with no blocks)
      // This keeps the database clean
      final orphanedTasksQuery = _database.selectOnly(_database.task)
        ..addColumns([_database.task.id])
        ..where(
          _database.task.id.isNotInQuery(
            _database.selectOnly(_database.block)
              ..addColumns([_database.block.taskId]),
          ),
        );

      final orphanedTasks = await orphanedTasksQuery.get();
      for (final task in orphanedTasks) {
        await (_database.delete(
          _database.task,
        )..where((t) => t.id.equals(task.read(_database.task.id)!))).go();
      }
    });

    await _loadScheduleForCurrentDate();
  }
}

final scheduleNotifierProvider =
    StateNotifierProvider<ScheduleNotifier, List<BlockWithTask>>((ref) {
      final database = ref.watch(databaseProvider);
      return ScheduleNotifier(database, ref);
    });
