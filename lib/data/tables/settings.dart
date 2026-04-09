import 'package:drift/drift.dart';

/// A table that can hold exactly one row (id must be 1).
class Settings extends Table {
  /// The lone primary-key row, fixed to the value 1.
  IntColumn get id =>
      integer().customConstraint('NOT NULL DEFAULT 1 CHECK (id = 1)')();

  IntColumn get defaultStartTime => integer()();
  IntColumn get defaultTaskLength => integer()();
  IntColumn get defaultBreakTime => integer()();

  /// When set, timeline opens filtered to this project; [defaultTimelineCategoryId] should be null.
  IntColumn get defaultTimelineProjectId => integer().nullable()();

  /// When no default project, optional category filter for the timeline.
  IntColumn get defaultTimelineCategoryId => integer().nullable()();

  /// Nullable so existing rows / partial reads never crash Drift's map(); treat null as true in app code.
  BoolColumn get defaultTimelineShowProjects => boolean().nullable()();

  BoolColumn get defaultTimelineUncompletedOnly => boolean().nullable()();

  /// JSON: pursuit focus slots, project queue, per-project task queues.
  TextColumn get pursuitStateJson => text().nullable()();

  // Sync Fields
  TextColumn get supabaseId => text().nullable()();
  DateTimeColumn get lastModified => dateTime()();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
