import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/tables/task.dart';

@TableIndex(name: 'idx_task_completion_task_id', columns: {#taskId})
@TableIndex(name: 'idx_task_completion_completed_at', columns: {#completedAt})
class TaskCompletion extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Task, #id, onDelete: KeyAction.cascade)();
  IntColumn get count => integer()();
  DateTimeColumn get completedAt => dateTime()();
}
