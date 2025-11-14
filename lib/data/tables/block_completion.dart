import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/tables/block.dart';

@TableIndex(name: 'idx_block_completion_block_id', columns: {#blockId})
@TableIndex(name: 'idx_block_completion_completed_at', columns: {#completedAt})
class BlockCompletion extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get blockId => integer().references(Block, #id)();
  IntColumn get count => integer()();
  DateTimeColumn get completedAt => dateTime()();

  // Sync Fields
  TextColumn get supabaseId => text().nullable()();
  DateTimeColumn get lastModified => dateTime()();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get version => integer().withDefault(const Constant(1))();
}
