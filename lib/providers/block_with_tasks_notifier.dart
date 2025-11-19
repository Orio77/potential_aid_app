import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/tables/block.dart';
import 'package:potential_aid_app/providers/database_provider.dart';

class BlockWithTasksNotifier extends StateNotifier<AsyncValue<BlockWithTasks>> {
  final AppDatabase _database;
  final int blockId;

  BlockWithTasksNotifier(this._database, this.blockId)
    : super(const AsyncValue.loading()) {
    _loadBlockWithTasks();
  }

  Future<void> _loadBlockWithTasks() async {
    try {
      final blockWithTasks = await _database.blockDao.getBlockWithTasks(
        blockId,
      );
      if (mounted) {
        state = AsyncValue.data(blockWithTasks);
      }
    } catch (e, trace) {
      if (mounted) {
        state = AsyncValue.error(e, trace);
      }
    }
  }
}

final blockTasksNotifier =
    StateNotifierProvider.family<
      BlockWithTasksNotifier,
      AsyncValue<BlockWithTasks>,
      int
    >((ref, blockId) {
      final database = ref.watch(databaseProvider);
      return BlockWithTasksNotifier(database, blockId);
    });
