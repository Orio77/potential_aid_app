import 'package:drift/drift.dart';

/// A table that can hold exactly one row (id must be 1).
class Settings extends Table {
  /// The lone primary-key row, fixed to the value 1.
  IntColumn get id =>
      integer().customConstraint('NOT NULL DEFAULT 1 CHECK (id = 1)')();

  IntColumn get defaultStartTime => integer()();
  IntColumn get defaultTaskLength => integer()();
  IntColumn get defaultBreakTime => integer()();
}
