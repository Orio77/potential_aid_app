import 'package:drift/drift.dart';

class ProjectCategory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().nullable()();
  IntColumn get iconCodePoint => integer().unique().nullable()();
  IntColumn get orderIndex => integer().nullable()();

  // Sync Fields
  TextColumn get supabaseId => text().nullable()();
  DateTimeColumn get lastModified => dateTime()();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
}
