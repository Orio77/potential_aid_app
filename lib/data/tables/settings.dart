import 'package:drift/drift.dart';

/// A table that can hold exactly one row (id must be 1).
class Settings extends Table {
  /// The lone primary-key row, fixed to the value 1.
  IntColumn get id =>
      integer().customConstraint('NOT NULL DEFAULT 1 CHECK (id = 1)')();

  IntColumn get defaultStartTime => integer()();
  IntColumn get defaultTaskLength => integer()();
  IntColumn get defaultBreakTime => integer()();

  // Sync Fields
  TextColumn get supabaseId => text().nullable()();
  DateTimeColumn get lastModified => dateTime()();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
