import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';

extension AppDatabaseCompletion on AppDatabase {
  Future<double?> getBlockCompletionPercentage(int blockId) async {
    final joined = select(blockCompletion).join([
      innerJoin(block, blockCompletion.blockId.equalsExp(block.id)),
    ])..where(blockCompletion.blockId.equals(blockId));

    final res = await joined.getSingleOrNull();

    if (res == null) {
      return null;
    }

    final completion = res.readTable(blockCompletion);
    final blockData = res.readTable(block);

    if (blockData.lengthMinutes == 0) {
      return 0.0;
    }

    final percentage = (completion.count / blockData.lengthMinutes * 100)
        .toDouble();

    return percentage;
  }

  Future<BlockCompletionData?> getCompletionForBlock(int blockId) async {
    final query = select(blockCompletion)
      ..where((completion) => completion.blockId.equals(blockId));

    return await query.getSingleOrNull();
  }

  Future<int> deleteCompletionForBlock(int blockId) {
    final query = delete(blockCompletion)
      ..where((completion) => completion.blockId.equals(blockId));

    return query.go();
  }
}
