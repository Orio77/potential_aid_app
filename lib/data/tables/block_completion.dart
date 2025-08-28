import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/tables/block.dart';

@TableIndex(name: 'idx_block_completion_block_id', columns: {#blockId})
@TableIndex(name: 'idx_block_completion_completed_at', columns: {#completedAt})
class BlockCompletion extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get blockId =>
      integer().references(Block, #id, onDelete: KeyAction.cascade)();
  IntColumn get count => integer()();
  DateTimeColumn get completedAt => dateTime()();
}
