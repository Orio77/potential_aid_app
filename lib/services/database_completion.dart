import 'package:drift/drift.dart';
import 'package:potential_aid_app/services/database.dart';

extension AppDatabaseCompletion on AppDatabase {
  Future<double> getBlockCompletionPercentage(int blockId) async {
    final joined = select(taskCompletion).join([
      innerJoin(block, taskCompletion.blockId.equalsExp(block.id)),
    ])..where(taskCompletion.blockId.equals(blockId));

    final res = await joined.getSingleOrNull();
    if (res == null) {
      return 0.0;
    }

    final completion = res.readTable(taskCompletion);
    final blockData = res.readTable(block);

    if (blockData.lengthMinutes == 0) {
      return 0.0;
    }

    return (completion.minutesCompleted / blockData.lengthMinutes * 100);
  }

  Future<TaskCompletionData?> getCompletionForBlock(int blockId) async {
    final query = select(taskCompletion)
      ..where((completion) => completion.blockId.equals(blockId));

    return await query.getSingleOrNull();
  }

  Future<int> deleteCompletionForBlock(int blockId) {
    final query = delete(taskCompletion)
      ..where((completion) => completion.blockId.equals(blockId));

    return query.go();
  }
}
