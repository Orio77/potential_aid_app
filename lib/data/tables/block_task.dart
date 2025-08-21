import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/tables/block.dart';
import 'package:potential_aid_app/data/tables/task.dart';

@TableIndex(name: 'idx_block_task_block_id', columns: {#blockId})
@TableIndex(name: 'idx_block_task_task_id', columns: {#taskId})
class BlockTask extends Table {
  IntColumn get blockId =>
      integer().references(Block, #id, onDelete: KeyAction.cascade)();
  IntColumn get taskId =>
      integer().references(Task, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column>? get primaryKey => {blockId, taskId};
}
