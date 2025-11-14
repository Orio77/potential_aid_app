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

  // Sync Fields
  TextColumn get supabaseId => text().nullable()();
  DateTimeColumn get lastModified => dateTime()();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
}
