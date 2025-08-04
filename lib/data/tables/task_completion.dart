import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/tables/block.dart';

@TableIndex(name: 'idx_task_completion_block_id', columns: {#blockId})
@TableIndex(name: 'idx_task_completion_completed_at', columns: {#completedAt})
class TaskCompletion extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get blockId =>
      integer().references(Block, #id, onDelete: KeyAction.cascade)();
  IntColumn get minutesCompleted => integer()();
  DateTimeColumn get completedAt => dateTime()();
}
