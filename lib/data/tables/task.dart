import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/tables/project.dart';

@TableIndex(name: 'idx_task_project_id', columns: {#projectId})
class Task extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get projectId =>
      integer().references(Project, #id, onDelete: KeyAction.cascade)();
  TextColumn get unit => text().nullable()();
  IntColumn get startPoint =>
      integer().nullable().withDefault(const Constant(0))();
  IntColumn get current => integer().withDefault(const Constant(0))();
  IntColumn get endGoal => integer().withDefault(const Constant(1))();
  DateTimeColumn get deadline => dateTime().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get parentTaskId =>
      integer().nullable().references(Task, #id, onDelete: KeyAction.cascade)();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  IntColumn get depth => integer().withDefault(const Constant(0))();

  // Sync Fields
  TextColumn get supabaseId => text().nullable()();
  DateTimeColumn get lastModified => dateTime()();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
}
