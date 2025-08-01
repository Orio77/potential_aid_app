import 'package:drift/drift.dart';

// One row table
class Settings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get defaultStartTime => integer()();
  IntColumn get defaultTaskLength => integer()();
  IntColumn get defaultBreakTime => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
