import 'package:potential_aid_app/data/database.dart';

extension AppDatabaseCompletion on AppDatabase {
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
