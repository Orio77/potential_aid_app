import 'package:drift/drift.dart';
import 'Task.dart';

class Block extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Task, #id)();
  DateTimeColumn get dayLocal => dateTime()();
  IntColumn get startMinuteOfDay => integer()();
  IntColumn get lengthMinutes => integer()();
}
