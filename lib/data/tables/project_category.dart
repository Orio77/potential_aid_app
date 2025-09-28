import 'package:drift/drift.dart';

class ProjectCategory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().nullable()();
  IntColumn get iconCodePoint => integer().unique().nullable()();
  IntColumn get orderIndex => integer().nullable()();
}
