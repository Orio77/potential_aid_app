import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/tables/task.dart';

@TableIndex(name: 'idx_task_completion_task_id', columns: {#taskId})
@TableIndex(name: 'idx_task_completion_completed_at', columns: {#completedAt})
class TaskCompletion extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Task, #id)();
  IntColumn get count => integer()();
  DateTimeColumn get completedAt => dateTime()();

  // Sync Fields
  TextColumn get supabaseId => text().nullable()();
  DateTimeColumn get lastModified => dateTime()();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
}
