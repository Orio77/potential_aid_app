import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';

extension AppDatabaseCompletion on AppDatabase {
  Future<double> getBlockCompletionPercentage(int blockId) async {
    print('getBlockCompletionPercentage called for blockId: $blockId');
    final joined = select(blockCompletion).join([
      innerJoin(block, blockCompletion.blockId.equalsExp(block.id)),
    ])..where(blockCompletion.blockId.equals(blockId));

    final res = await joined.getSingleOrNull();
    print('getBlockCompletionPercentage blockId $blockId: query result = $res');
    if (res == null) {
      print(
        'getBlockCompletionPercentage blockId $blockId: no completion found, returning 0.0',
      );
      return 0.0;
    }

    final completion = res.readTable(blockCompletion);
    final blockData = res.readTable(block);
    print(
      'getBlockCompletionPercentage blockId $blockId: completion.count=${completion.count}, blockData.lengthMinutes=${blockData.lengthMinutes}',
    );

    if (blockData.lengthMinutes == 0) {
      print(
        'getBlockCompletionPercentage blockId $blockId: block length is 0, returning 0.0',
      );
      return 0.0;
    }

    final percentage = (completion.count / blockData.lengthMinutes * 100);
    print(
      'getBlockCompletionPercentage blockId $blockId: calculated percentage = $percentage',
    );
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
