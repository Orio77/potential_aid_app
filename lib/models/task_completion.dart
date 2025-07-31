import 'package:drift/drift.dart';
import 'package:potential_aid_app/models/block.dart';

class TaskCompletion extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get blockId => integer().references(Block, #id)();
  IntColumn get minutesCompleted => integer()();
  DateTimeColumn get completedAt => dateTime()();

  @override
  List<String> get customConstraints => [
    'CREATE INDEX IF NOT EXISTS idx_task_completion_block_id ON task_completion(block_id)',
    'CREATE INDEX IF NOT EXISTS idx_task_completion_completed_at ON task_completion(completed_at)',
  ];
}
