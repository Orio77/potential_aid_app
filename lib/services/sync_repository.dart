import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/utils/sync_converter.dart';

/// Repository for sync-related database operations
class SyncRepository {
  final AppDatabase _database;

  // Cache for ID mappings
  final Map<String, Map<int, String?>> _localToSupabaseCache = {};
  final Map<String, Map<String, int>> _supabaseToLocalCache = {};

  SyncRepository(this._database);

  AppDatabase get database => _database;

  /// Reset lookup caches
  void resetCaches() {
    _localToSupabaseCache.clear();
    _supabaseToLocalCache.clear();
  }

  /// Get records that need to be synced for a given table
  Future<List<Map<String, dynamic>>> getRecordsNeedingSync(
    String tableName,
  ) async {
    try {
      switch (tableName) {
        case 'task':
          final tasks = await (_database.select(
            _database.task,
          )..where((t) => t.needsSync.equals(true))).get();
          return tasks.map((t) => t.toJson()).toList();

        case 'project':
          final projects = await (_database.select(
            _database.project,
          )..where((p) => p.needsSync.equals(true))).get();
          return projects.map((p) => p.toJson()).toList();

        case 'project_category':
          final categories = await (_database.select(
            _database.projectCategory,
          )..where((pc) => pc.needsSync.equals(true))).get();
          return categories.map((pc) => pc.toJson()).toList();

        case 'block':
          final blocks = await (_database.select(
            _database.block,
          )..where((b) => b.needsSync.equals(true))).get();
          return blocks.map((b) => b.toJson()).toList();

        case 'task_completion':
          final completions = await (_database.select(
            _database.taskCompletion,
          )..where((tc) => tc.needsSync.equals(true))).get();
          return completions.map((tc) => tc.toJson()).toList();

        case 'block_completion':
          final completions = await (_database.select(
            _database.blockCompletion,
          )..where((bc) => bc.needsSync.equals(true))).get();
          return completions.map((bc) => bc.toJson()).toList();

        case 'block_task':
          final blockTasks = await (_database.select(
            _database.blockTask,
          )..where((bt) => bt.needsSync.equals(true))).get();
          return blockTasks.map((bt) => bt.toJson()).toList();

        case 'settings':
          final settings = await (_database.select(
            _database.settings,
          )..where((s) => s.needsSync.equals(true))).get();
          return settings.map((s) => s.toJson()).toList();

        default:
          return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Get all records from a local table
  Future<List<Map<String, dynamic>>> getAllRecords(String tableName) async {
    try {
      switch (tableName) {
        case 'task':
          final tasks = await _database.select(_database.task).get();
          return tasks.map((t) => t.toJson()).toList();

        case 'project':
          final projects = await _database.select(_database.project).get();
          return projects.map((p) => p.toJson()).toList();

        case 'project_category':
          final categories = await _database
              .select(_database.projectCategory)
              .get();
          return categories.map((pc) => pc.toJson()).toList();

        case 'block':
          final blocks = await _database.select(_database.block).get();
          return blocks.map((b) => b.toJson()).toList();

        case 'task_completion':
          final completions = await _database
              .select(_database.taskCompletion)
              .get();
          return completions.map((tc) => tc.toJson()).toList();

        case 'block_completion':
          final completions = await _database
              .select(_database.blockCompletion)
              .get();
          return completions.map((bc) => bc.toJson()).toList();

        case 'block_task':
          final blockTasks = await _database.select(_database.blockTask).get();
          return blockTasks.map((bt) => bt.toJson()).toList();

        case 'settings':
          final settings = await _database.select(_database.settings).get();
          return settings.map((s) => s.toJson()).toList();

        default:
          return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Get Supabase ID for a local ID
  Future<String?> getSupabaseIdForLocal(String tableName, int? localId) async {
    if (localId == null) return null;
    final cache = _localToSupabaseCache.putIfAbsent(tableName, () => {});
    if (cache.containsKey(localId)) {
      return cache[localId];
    }

    String? supabaseId;
    switch (tableName) {
      case 'task':
        supabaseId = (await (_database.select(
          _database.task,
        )..where((t) => t.id.equals(localId))).getSingleOrNull())?.supabaseId;
        break;
      case 'project':
        supabaseId = (await (_database.select(
          _database.project,
        )..where((p) => p.id.equals(localId))).getSingleOrNull())?.supabaseId;
        break;
      case 'project_category':
        supabaseId = (await (_database.select(
          _database.projectCategory,
        )..where((pc) => pc.id.equals(localId))).getSingleOrNull())?.supabaseId;
        break;
      case 'block':
        supabaseId = (await (_database.select(
          _database.block,
        )..where((b) => b.id.equals(localId))).getSingleOrNull())?.supabaseId;
        break;
      case 'task_completion':
        supabaseId = (await (_database.select(
          _database.taskCompletion,
        )..where((tc) => tc.id.equals(localId))).getSingleOrNull())?.supabaseId;
        break;
      case 'block_completion':
        supabaseId = (await (_database.select(
          _database.blockCompletion,
        )..where((bc) => bc.id.equals(localId))).getSingleOrNull())?.supabaseId;
        break;
      case 'settings':
        supabaseId = (await (_database.select(
          _database.settings,
        )..where((s) => s.id.equals(localId))).getSingleOrNull())?.supabaseId;
        break;
      default:
        break;
    }

    cache[localId] = supabaseId;
    return supabaseId;
  }

  /// Get local ID for a Supabase ID
  Future<int?> getLocalIdForSupabase(
    String tableName,
    String? supabaseId,
  ) async {
    if (supabaseId == null) return null;
    final cache = _supabaseToLocalCache.putIfAbsent(tableName, () => {});
    if (cache.containsKey(supabaseId)) {
      return cache[supabaseId];
    }

    int? localId;
    switch (tableName) {
      case 'task':
        localId =
            (await (_database.select(_database.task)
                      ..where((t) => t.supabaseId.equals(supabaseId)))
                    .getSingleOrNull())
                ?.id;
        break;
      case 'project':
        localId =
            (await (_database.select(_database.project)
                      ..where((p) => p.supabaseId.equals(supabaseId)))
                    .getSingleOrNull())
                ?.id;
        break;
      case 'project_category':
        localId =
            (await (_database.select(_database.projectCategory)
                      ..where((pc) => pc.supabaseId.equals(supabaseId)))
                    .getSingleOrNull())
                ?.id;
        break;
      case 'block':
        localId =
            (await (_database.select(_database.block)
                      ..where((b) => b.supabaseId.equals(supabaseId)))
                    .getSingleOrNull())
                ?.id;
        break;
      case 'task_completion':
        localId =
            (await (_database.select(_database.taskCompletion)
                      ..where((tc) => tc.supabaseId.equals(supabaseId)))
                    .getSingleOrNull())
                ?.id;
        break;
      case 'block_completion':
        localId =
            (await (_database.select(_database.blockCompletion)
                      ..where((bc) => bc.supabaseId.equals(supabaseId)))
                    .getSingleOrNull())
                ?.id;
        break;
      case 'settings':
        localId =
            (await (_database.select(_database.settings)
                      ..where((s) => s.supabaseId.equals(supabaseId)))
                    .getSingleOrNull())
                ?.id;
        break;
      default:
        break;
    }

    if (localId != null) {
      cache[supabaseId] = localId;
    }
    return localId;
  }

  /// Set Supabase ID for a local record
  Future<void> setRecordSupabaseId(
    String tableName,
    int localId,
    String supabaseId,
  ) async {
    switch (tableName) {
      case 'task':
        await (_database.update(_database.task)
              ..where((t) => t.id.equals(localId)))
            .write(TaskCompanion(supabaseId: Value(supabaseId)));
        break;
      case 'project':
        await (_database.update(_database.project)
              ..where((p) => p.id.equals(localId)))
            .write(ProjectCompanion(supabaseId: Value(supabaseId)));
        break;
      case 'project_category':
        await (_database.update(_database.projectCategory)
              ..where((pc) => pc.id.equals(localId)))
            .write(ProjectCategoryCompanion(supabaseId: Value(supabaseId)));
        break;
      case 'block':
        await (_database.update(_database.block)
              ..where((b) => b.id.equals(localId)))
            .write(BlockCompanion(supabaseId: Value(supabaseId)));
        break;
      case 'task_completion':
        await (_database.update(_database.taskCompletion)
              ..where((tc) => tc.id.equals(localId)))
            .write(TaskCompletionCompanion(supabaseId: Value(supabaseId)));
        break;
      case 'block_completion':
        await (_database.update(_database.blockCompletion)
              ..where((bc) => bc.id.equals(localId)))
            .write(BlockCompletionCompanion(supabaseId: Value(supabaseId)));
        break;
      case 'settings':
        await (_database.update(_database.settings)
              ..where((s) => s.id.equals(localId)))
            .write(SettingsCompanion(supabaseId: Value(supabaseId)));
        break;
      default:
        break;
    }

    _localToSupabaseCache.putIfAbsent(tableName, () => {})[localId] =
        supabaseId;
    _supabaseToLocalCache.putIfAbsent(tableName, () => {})[supabaseId] =
        localId;
  }

  /// Set Supabase ID for BlockTask using composite key
  Future<void> setBlockTaskSupabaseId(
    int blockId,
    int taskId,
    String supabaseId,
  ) async {
    await (_database.update(
          _database.blockTask,
        )..where((bt) => bt.blockId.equals(blockId) & bt.taskId.equals(taskId)))
        .write(BlockTaskCompanion(supabaseId: Value(supabaseId)));
  }

  /// Find local record by Supabase ID
  Future<Map<String, dynamic>?> findLocalRecordBySupabaseId(
    String tableName,
    String supabaseId,
  ) async {
    try {
      switch (tableName) {
        case 'task':
          final result = await (_database.select(
            _database.task,
          )..where((t) => t.supabaseId.equals(supabaseId))).getSingleOrNull();
          return result?.toJson();
        case 'project':
          final result = await (_database.select(
            _database.project,
          )..where((p) => p.supabaseId.equals(supabaseId))).getSingleOrNull();
          return result?.toJson();
        case 'project_category':
          final result = await (_database.select(
            _database.projectCategory,
          )..where((pc) => pc.supabaseId.equals(supabaseId))).getSingleOrNull();
          return result?.toJson();
        case 'block':
          final result = await (_database.select(
            _database.block,
          )..where((b) => b.supabaseId.equals(supabaseId))).getSingleOrNull();
          return result?.toJson();
        case 'task_completion':
          final result = await (_database.select(
            _database.taskCompletion,
          )..where((tc) => tc.supabaseId.equals(supabaseId))).getSingleOrNull();
          return result?.toJson();
        case 'block_completion':
          final result = await (_database.select(
            _database.blockCompletion,
          )..where((bc) => bc.supabaseId.equals(supabaseId))).getSingleOrNull();
          return result?.toJson();
        case 'block_task':
          final result = await (_database.select(
            _database.blockTask,
          )..where((bt) => bt.supabaseId.equals(supabaseId))).getSingleOrNull();
          return result?.toJson();
        case 'settings':
          final result = await (_database.select(
            _database.settings,
          )..where((s) => s.supabaseId.equals(supabaseId))).getSingleOrNull();
          return result?.toJson();
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Delete local records by IDs
  Future<void> deleteLocalRecordsByIds(
    String localTable,
    List<int> ids,
  ) async {
    switch (localTable) {
      case 'task':
        await (_database.delete(
          _database.task,
        )..where((t) => t.id.isIn(ids))).go();
        break;
      case 'project':
        await (_database.delete(
          _database.project,
        )..where((p) => p.id.isIn(ids))).go();
        break;
      case 'project_category':
        await (_database.delete(
          _database.projectCategory,
        )..where((pc) => pc.id.isIn(ids))).go();
        break;
      case 'block':
        await (_database.delete(
          _database.block,
        )..where((b) => b.id.isIn(ids))).go();
        break;
      case 'task_completion':
        await (_database.delete(
          _database.taskCompletion,
        )..where((tc) => tc.id.isIn(ids))).go();
        break;
      case 'block_completion':
        await (_database.delete(
          _database.blockCompletion,
        )..where((bc) => bc.id.isIn(ids))).go();
        break;
      case 'settings':
        await (_database.delete(
          _database.settings,
        )..where((s) => s.id.isIn(ids))).go();
        break;
      default:
    }
  }

  /// Delete BlockTask by Supabase ID
  Future<void> deleteBlockTaskBySupabaseId(String supabaseId) async {
    await (_database.delete(
      _database.blockTask,
    )..where((bt) => bt.supabaseId.equals(supabaseId))).go();
  }

  /// Mark records as synced (batch operation)
  Future<void> batchMarkRecordsAsSynced(
    String tableName,
    List<Map<String, dynamic>> records,
  ) async {
    if (records.isEmpty) return;

    try {
      await _database.batch((batch) {
        for (final record in records) {
          final recordId = SyncConverter.getField<int>(record, 'id');
          if (recordId != null) {
            switch (tableName) {
              case 'task':
                batch.update(
                  _database.task,
                  const TaskCompanion(needsSync: Value(false)),
                  where: (t) => t.id.equals(recordId),
                );
                break;
              case 'project':
                batch.update(
                  _database.project,
                  const ProjectCompanion(needsSync: Value(false)),
                  where: (p) => p.id.equals(recordId),
                );
                break;
              case 'project_category':
                batch.update(
                  _database.projectCategory,
                  const ProjectCategoryCompanion(needsSync: Value(false)),
                  where: (pc) => pc.id.equals(recordId),
                );
                break;
              case 'block':
                batch.update(
                  _database.block,
                  const BlockCompanion(needsSync: Value(false)),
                  where: (b) => b.id.equals(recordId),
                );
                break;
              case 'task_completion':
                batch.update(
                  _database.taskCompletion,
                  const TaskCompletionCompanion(needsSync: Value(false)),
                  where: (tc) => tc.id.equals(recordId),
                );
                break;
              case 'block_completion':
                batch.update(
                  _database.blockCompletion,
                  const BlockCompletionCompanion(needsSync: Value(false)),
                  where: (bc) => bc.id.equals(recordId),
                );
                break;
              case 'block_task':
                final blockId = SyncConverter.getField<int>(record, 'blockId');
                final taskId = SyncConverter.getField<int>(record, 'taskId');
                if (blockId != null && taskId != null) {
                  batch.update(
                    _database.blockTask,
                    const BlockTaskCompanion(needsSync: Value(false)),
                    where: (bt) =>
                        bt.blockId.equals(blockId) & bt.taskId.equals(taskId),
                  );
                }
                break;
              case 'settings':
                batch.update(
                  _database.settings,
                  const SettingsCompanion(needsSync: Value(false)),
                  where: (s) => s.id.equals(recordId),
                );
                break;
            }
          }
        }
      });
    } catch (e) {
      rethrow;
    }
  }
}
