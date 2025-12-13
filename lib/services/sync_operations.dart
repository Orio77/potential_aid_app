import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/models/sync_models.dart';
import 'package:potential_aid_app/services/supabase_service.dart';
import 'package:potential_aid_app/services/sync_repository.dart';
import 'package:potential_aid_app/services/sync_record_mapper.dart';
import 'package:potential_aid_app/utils/sync_converter.dart';
import 'package:uuid/uuid.dart';

/// Handles sync operations (push, pull, migration)
class SyncOperations {
  final SyncRepository _repository;
  final SupabaseService _supabaseService;
  final SyncRecordMapper _recordMapper;
  final Uuid _uuid = const Uuid();

  // Table mapping: local table name -> remote table name
  static const Map<String, String> tableMapping = {
    'project_category': 'project_category',
    'project': 'project',
    'task': 'task',
    'block': 'block',
    'block_task': 'block_task',
    'task_completion': 'task_completion',
    'block_completion': 'block_completion',
    'settings': 'settings',
  };

  SyncOperations(
    this._repository,
    this._supabaseService,
    this._recordMapper,
  );

  /// Handle initial migration when local DB has existing data
  Future<SyncResult> performInitialMigration() async {
    int totalRecords = 0;
    Map<String, int> tableStats = {};

    try {
      for (final entry in tableMapping.entries) {
        final localTable = entry.key;
        final remoteTable = entry.value;

        final recordsToMigrate = await _repository.getAllRecords(localTable);

        if (recordsToMigrate.isNotEmpty) {
          final remoteRecords = <Map<String, dynamic>>[];
          for (final record in recordsToMigrate) {
            final supabaseId = await _ensureSupabaseIdValue(localTable, record);
            final remoteRecord = await _recordMapper.convertLocalToRemote(
              localTable,
              record,
              supabaseId,
            );
            remoteRecords.add(remoteRecord);
          }

          final uploadedRecords = await _supabaseService.upsertRecords(
            remoteTable,
            remoteRecords,
          );

          await _updateLocalWithRemoteIds(
            localTable,
            recordsToMigrate,
            uploadedRecords,
          );

          tableStats[localTable] = recordsToMigrate.length;
          totalRecords = totalRecords + recordsToMigrate.length;
        }
      }

      return SyncResult(
        success: true,
        recordsSynced: totalRecords,
        tableStats: tableStats,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Push local changes to remote
  Future<SyncResult> pushLocalChanges() async {
    int totalRecords = 0;
    Map<String, int> tableStats = {};

    try {
      for (final entry in tableMapping.entries) {
        final localTable = entry.key;
        final remoteTable = entry.value;

        final recordsToSync = await _repository.getRecordsNeedingSync(
          localTable,
        );

        if (recordsToSync.isNotEmpty) {
          final (creates, updates, deletes) = _categorizeRecords(recordsToSync);

          // Handle creates and updates
          if (creates.isNotEmpty || updates.isNotEmpty) {
            final upsertRecords = <Map<String, dynamic>>[];
            for (final record in [...creates, ...updates]) {
              final supabaseId = await _ensureSupabaseIdValue(
                localTable,
                record,
              );
              final remoteRecord = await _recordMapper.convertLocalToRemote(
                localTable,
                record,
                supabaseId,
              );
              upsertRecords.add(remoteRecord);
            }

            final uploadedRecords = await _supabaseService.upsertRecords(
              remoteTable,
              upsertRecords,
            );

            await _markRecordsAsSynced(localTable, [
              ...creates,
              ...updates,
            ], uploadedRecords);
          }

          // Handle deletes
          if (deletes.isNotEmpty) {
            final supabaseIds = deletes
                .map((r) => SyncConverter.getField<String>(r, 'supabaseId'))
                .whereType<String>()
                .toList();
            final ids = deletes
                .map((r) => SyncConverter.getField<int>(r, 'id'))
                .whereType<int>()
                .toList();

            if (supabaseIds.isNotEmpty) {
              await _supabaseService.deleteRecords(remoteTable, supabaseIds);
            }

            await _markRecordsAsSynced(localTable, deletes, []);
            await _repository.deleteLocalRecordsByIds(localTable, ids);
          }

          tableStats[localTable] = recordsToSync.length;
          totalRecords += recordsToSync.length;
        }
      }

      return SyncResult(
        success: true,
        recordsSynced: totalRecords,
        tableStats: tableStats,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Pull remote changes and apply to local database
  Future<SyncResult> pullRemoteChanges(DateTime? lastSyncTime) async {
    int totalRecords = 0;
    Map<String, int> tableStats = {};

    try {
      for (final entry in tableMapping.entries) {
        final localTable = entry.key;
        final remoteTable = entry.value;

        final remoteRecords = await _supabaseService.fetchRecords(
          remoteTable,
          userId: _supabaseService.currentUserId,
          lastSyncTime: lastSyncTime,
        );

        if (remoteRecords.isNotEmpty) {
          // Sort tasks by depth to ensure parents are processed before children
          if (localTable == 'task') {
            remoteRecords.sort((a, b) {
              final depthA = a['depth'] as int? ?? 0;
              final depthB = b['depth'] as int? ?? 0;
              return depthA.compareTo(depthB);
            });
          }

          for (final remoteRecord in remoteRecords) {
            await _recordMapper.applyRemoteChangeToLocal(
              localTable,
              remoteRecord,
            );
          }

          tableStats[localTable] = remoteRecords.length;
          totalRecords += remoteRecords.length;
        }
      }

      return SyncResult(
        success: true,
        recordsSynced: totalRecords,
        tableStats: tableStats,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Helper methods

  /// Ensure a record has a Supabase ID
  Future<String> _ensureSupabaseIdValue(
    String tableName,
    Map<String, dynamic> record,
  ) async {
    final existing = SyncConverter.getField<String>(record, 'supabaseId');
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final newId = _uuid.v4();
    await _setLocalSupabaseId(tableName, record, newId);
    record['supabaseId'] = newId;
    return newId;
  }

  /// Set local Supabase ID
  Future<void> _setLocalSupabaseId(
    String tableName,
    Map<String, dynamic> record,
    String supabaseId,
  ) async {
    if (tableName == 'block_task') {
      final blockId = SyncConverter.getField<int>(record, 'blockId');
      final taskId = SyncConverter.getField<int>(record, 'taskId');
      if (blockId != null && taskId != null) {
        await _repository.setBlockTaskSupabaseId(blockId, taskId, supabaseId);
      }
      return;
    }

    final localId = SyncConverter.getField<int>(record, 'id');
    if (localId == null) return;
    await _repository.setRecordSupabaseId(tableName, localId, supabaseId);
  }

  /// Update local records with remote IDs after migration
  Future<void> _updateLocalWithRemoteIds(
    String tableName,
    List<Map<String, dynamic>> localRecords,
    List<Map<String, dynamic>> uploadedRecords,
  ) async {
    for (
      int i = 0;
      i < localRecords.length && i < uploadedRecords.length;
      i++
    ) {
      final localRecord = localRecords[i];
      final uploadedRecord = uploadedRecords[i];
      final supabaseId = uploadedRecord['supabase_id'] as String;

      if (tableName == 'block_task') {
        final blockId = SyncConverter.getField<int>(localRecord, 'blockId');
        final taskId = SyncConverter.getField<int>(localRecord, 'taskId');
        if (blockId == null || taskId == null) {
          continue;
        }
        await _updateBlockTaskSupabaseId(blockId, taskId, supabaseId);
      } else {
        final localId = SyncConverter.getField<int>(localRecord, 'id');
        if (localId == null) {
          continue;
        }
        await _updateRecordSupabaseId(tableName, localId, supabaseId);
      }
    }
  }

  /// Update a specific record's Supabase ID
  Future<void> _updateRecordSupabaseId(
    String tableName,
    int localId,
    String supabaseId,
  ) async {
    final now = DateTime.now();
    final db = _repository.database;

    switch (tableName) {
      case 'task':
        await (db.update(db.task)..where((t) => t.id.equals(localId))).write(
          TaskCompanion(
            supabaseId: Value(supabaseId),
            needsSync: const Value(false),
            lastModified: Value(now),
          ),
        );
        break;
      case 'project':
        await (db.update(db.project)..where((p) => p.id.equals(localId))).write(
          ProjectCompanion(
            supabaseId: Value(supabaseId),
            needsSync: const Value(false),
            lastModified: Value(now),
          ),
        );
        break;
      case 'project_category':
        await (db.update(db.projectCategory)..where((pc) => pc.id.equals(localId))).write(
          ProjectCategoryCompanion(
            supabaseId: Value(supabaseId),
            needsSync: const Value(false),
            lastModified: Value(now),
          ),
        );
        break;
      case 'block':
        await (db.update(db.block)..where((b) => b.id.equals(localId))).write(
          BlockCompanion(
            supabaseId: Value(supabaseId),
            needsSync: const Value(false),
            lastModified: Value(now),
          ),
        );
        break;
      case 'task_completion':
        await (db.update(db.taskCompletion)..where((tc) => tc.id.equals(localId))).write(
          TaskCompletionCompanion(
            supabaseId: Value(supabaseId),
            needsSync: const Value(false),
            lastModified: Value(now),
          ),
        );
        break;
      case 'block_completion':
        await (db.update(db.blockCompletion)..where((bc) => bc.id.equals(localId))).write(
          BlockCompletionCompanion(
            supabaseId: Value(supabaseId),
            needsSync: const Value(false),
            lastModified: Value(now),
          ),
        );
        break;
      case 'settings':
        await (db.update(db.settings)..where((s) => s.id.equals(localId))).write(
          SettingsCompanion(
            supabaseId: Value(supabaseId),
            needsSync: const Value(false),
            lastModified: Value(now),
          ),
        );
        break;
      default:
    }
  }

  /// Update BlockTask Supabase ID
  Future<void> _updateBlockTaskSupabaseId(
    int blockId,
    int taskId,
    String supabaseId,
  ) async {
    final now = DateTime.now();
    final db = _repository.database;

    await (db.update(db.blockTask)
          ..where((bt) => bt.blockId.equals(blockId) & bt.taskId.equals(taskId)))
        .write(
          BlockTaskCompanion(
            supabaseId: Value(supabaseId),
            needsSync: const Value(false),
            lastModified: Value(now),
          ),
        );
  }

  /// Categorize records into creates, updates, and deletes
  (
    List<Map<String, dynamic>>,
    List<Map<String, dynamic>>,
    List<Map<String, dynamic>>,
  )
  _categorizeRecords(List<Map<String, dynamic>> records) {
    final creates = <Map<String, dynamic>>[];
    final updates = <Map<String, dynamic>>[];
    final deletes = <Map<String, dynamic>>[];

    for (final record in records) {
      final rawDeleted = SyncConverter.getField<dynamic>(record, 'isDeleted');
      final isDeleted = rawDeleted == true || rawDeleted == 1;
      final hasSupabaseId = SyncConverter.getField<String>(
            record,
            'supabaseId',
          ) !=
          null;

      if (isDeleted) {
        deletes.add(record);
      } else if (hasSupabaseId) {
        updates.add(record);
      } else {
        creates.add(record);
      }
    }

    return (creates, updates, deletes);
  }

  /// Mark records as synced
  Future<void> _markRecordsAsSynced(
    String tableName,
    List<Map<String, dynamic>> records,
    List<Map<String, dynamic>> uploadedRecords,
  ) async {
    try {
      await _repository.batchMarkRecordsAsSynced(tableName, records);
    } catch (e) {
      rethrow;
    }
  }
}
