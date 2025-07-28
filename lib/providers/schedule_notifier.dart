import 'package:drift/drift.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/services/database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScheduleNotifier extends StateNotifier<List<BlockData>> {
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
    final blocks = await _getBlocks();

    state = blocks;
  }

  Future<List<BlockData>> _getBlocks() async {
    final currentDate = _ref.read(dateNotifierProvider);
    final dateTime = currentDate.atMidnight().toDateTimeLocal();

    final query = _database.select(_database.block)
      ..where((block) => block.dayLocal.equals(dateTime))
      ..orderBy([(block) => OrderingTerm.asc(block.startMinuteOfDay)]);

    final blocks = await query.get();

    return blocks;
  }

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
    final blocks = await _getBlocks();
    if (oldIndex == newIndex ||
        oldIndex >= blocks.length ||
        newIndex >= blocks.length) {
      return;
    }

    final first = blocks[oldIndex];
    final second = blocks[newIndex];

    await _database.transaction(() async {
      await (_database.update(
        _database.block,
      )..where((b) => b.id.equals(first.id))).write(
        BlockCompanion(startMinuteOfDay: Value(second.startMinuteOfDay)),
      );

      await (_database.update(
        _database.block,
      )..where((b) => b.id.equals(second.id))).write(
        BlockCompanion(startMinuteOfDay: Value(first.startMinuteOfDay)),
      );
    });

    await _loadScheduleForCurrentDate();
  }
}

final scheduleNotifierProvider =
    StateNotifierProvider<ScheduleNotifier, List<BlockData>>((ref) {
      final database = ref.watch(databaseProvider);
      return ScheduleNotifier(database, ref);
    });
