import 'package:drift/drift.dart';

class Task extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get estimatedMinutes => integer()();
  IntColumn get projectId => integer().nullable()();
}
