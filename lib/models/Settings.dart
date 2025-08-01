import 'package:drift/drift.dart';

// One row table
class Settings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get defaultStartTime => integer()();
  IntColumn get defaultTaskLength => integer()();
  IntColumn get defaultBreakTime => integer()();
}
