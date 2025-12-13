import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/services/supabase_service.dart';
import 'package:potential_aid_app/services/sync_repository.dart';
import 'package:potential_aid_app/utils/sync_converter.dart';

/// Handles complex record mapping and conversion between local and remote formats
class SyncRecordMapper {
  final SyncRepository _repository;
  final SupabaseService _supabaseService;

  SyncRecordMapper(this._repository, this._supabaseService);

  /// Convert local record to remote format
  Future<Map<String, dynamic>> convertLocalToRemote(
    String tableName,
    Map<String, dynamic> localRecord,
    String supabaseId,
  ) async {
    final remoteRecord = <String, dynamic>{};

    localRecord.forEach((key, value) {
      if (key == 'id') {
        return; // never sync local primary keys
      }

      final remoteKey = SyncConverter.getColumnName(tableName, key);
      remoteRecord[remoteKey] = SyncConverter.normalizeValue(
        value,
        fieldName: remoteKey,
      );
    });

    // Ensure required metadata is present
    remoteRecord['supabase_id'] = remoteRecord['supabase_id'] ?? supabaseId;
    remoteRecord['user_id'] = _supabaseService.currentUserId;
    remoteRecord['last_modified'] = remoteRecord['last_modified'] ??
        SyncConverter.normalizeValue(
          localRecord['lastModified'] ?? DateTime.now().toIso8601String(),
          fieldName: 'last_modified',
        );

    final relationFields = await _buildRelationFields(
      tableName,
      localRecord,
      supabaseId,
    );
    remoteRecord.addAll(relationFields);

    return remoteRecord;
  }

  /// Build foreign key relation fields for remote record
  Future<Map<String, dynamic>> _buildRelationFields(
    String tableName,
    Map<String, dynamic> localRecord,
    String supabaseId,
  ) async {
    final relationFields = <String, dynamic>{};

    switch (tableName) {
      case 'task':
        final projectSupabaseId = await _repository.getSupabaseIdForLocal(
          'project',
          SyncConverter.getField<int>(localRecord, 'projectId'),
        );
        final parentTaskSupabaseId = await _repository.getSupabaseIdForLocal(
          'task',
          SyncConverter.getField<int>(localRecord, 'parentTaskId'),
        );
        if (projectSupabaseId != null) {
          relationFields['project_supabase_id'] = projectSupabaseId;
        }
        if (parentTaskSupabaseId != null) {
          relationFields['parent_task_supabase_id'] = parentTaskSupabaseId;
        }
        break;
      case 'project':
        final parentProjectSupabaseId = await _repository.getSupabaseIdForLocal(
          'project',
          SyncConverter.getField<int>(localRecord, 'parentProjectId'),
        );
        final categorySupabaseId = await _repository.getSupabaseIdForLocal(
          'project_category',
          SyncConverter.getField<int>(localRecord, 'category'),
        );
        if (parentProjectSupabaseId != null) {
          relationFields['parent_project_supabase_id'] =
              parentProjectSupabaseId;
        }
        if (categorySupabaseId != null) {
          relationFields['category_supabase_id'] = categorySupabaseId;
        }
        break;
      case 'block':
        final projectSupabaseId = await _repository.getSupabaseIdForLocal(
          'project',
          SyncConverter.getField<int>(localRecord, 'projectId'),
        );
        if (projectSupabaseId != null) {
          relationFields['project_supabase_id'] = projectSupabaseId;
        }
        break;
      case 'block_task':
        final blockSupabaseId = await _repository.getSupabaseIdForLocal(
          'block',
          SyncConverter.getField<int>(localRecord, 'blockId'),
        );
        final taskSupabaseId = await _repository.getSupabaseIdForLocal(
          'task',
          SyncConverter.getField<int>(localRecord, 'taskId'),
        );
        if (blockSupabaseId != null && taskSupabaseId != null) {
          relationFields['block_supabase_id'] = blockSupabaseId;
          relationFields['task_supabase_id'] = taskSupabaseId;
        }
        break;
      case 'task_completion':
        final taskSupabaseId = await _repository.getSupabaseIdForLocal(
          'task',
          SyncConverter.getField<int>(localRecord, 'taskId'),
        );
        if (taskSupabaseId != null) {
          relationFields['task_supabase_id'] = taskSupabaseId;
        }
        break;
      case 'block_completion':
        final blockSupabaseId = await _repository.getSupabaseIdForLocal(
          'block',
          SyncConverter.getField<int>(localRecord, 'blockId'),
        );
        if (blockSupabaseId != null) {
          relationFields['block_supabase_id'] = blockSupabaseId;
        }
        break;
      default:
        break;
    }

    relationFields.removeWhere((key, value) => value == null);
    return relationFields;
  }

  /// Apply remote change to local database with conflict resolution
  Future<void> applyRemoteChangeToLocal(
    String tableName,
    Map<String, dynamic> remoteRecord,
  ) async {
    try {
      final supabaseId = remoteRecord['supabase_id'] as String?;
      if (supabaseId == null) {
        return;
      }

      // Check if local record exists
      final existingLocal = await _repository.findLocalRecordBySupabaseId(
        tableName,
        supabaseId,
      );

      // Parse remote timestamps
      final remoteModified = SyncConverter.parseDateTime(
        remoteRecord['last_modified'],
      );
      final remoteVersion = remoteRecord['version'] as int? ?? 1;
      final isRemoteDeleted =
          remoteRecord['is_deleted'] == true || remoteRecord['is_deleted'] == 1;

      if (existingLocal == null) {
        // No local record exists - insert if not deleted
        if (!isRemoteDeleted) {
          await _insertRemoteRecord(tableName, remoteRecord);
        }
        return;
      }

      // Local record exists - resolve conflicts
      final localModified = existingLocal['last_modified'] as DateTime?;
      final localVersion = existingLocal['version'] as int? ?? 1;
      final localNeedsSync = existingLocal['needs_sync'] as bool? ?? false;
      final requiresLocalId = tableName != 'block_task';
      final int? localId = requiresLocalId ? existingLocal['id'] as int? : null;

      if (requiresLocalId && localId == null) {
        return;
      }

      // Handle remote deletion
      if (isRemoteDeleted) {
        if (tableName == 'block_task') {
          await _repository.deleteBlockTaskBySupabaseId(supabaseId);
        } else {
          await _repository.deleteLocalRecordsByIds(tableName, [localId!]);
        }
        return;
      }

      // Conflict resolution for non-deleted records
      if (localNeedsSync) {
        // Local has pending changes - use version-based resolution
        if (remoteVersion > localVersion) {
          if (remoteModified != null && localModified != null) {
            if (remoteModified.isAfter(localModified)) {
              await _updateLocalWithRemote(
                tableName,
                tableName == 'block_task' ? 0 : localId!,
                remoteRecord,
              );
            }
          } else {
            await _updateLocalWithRemote(
              tableName,
              tableName == 'block_task' ? 0 : localId!,
              remoteRecord,
            );
          }
        }
      } else {
        // No local pending changes - safe to apply remote
        await _updateLocalWithRemote(
          tableName,
          tableName == 'block_task' ? 0 : localId!,
          remoteRecord,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Insert new record from remote data
  Future<void> _insertRemoteRecord(
    String tableName,
    Map<String, dynamic> remoteRecord,
  ) async {
    final now = DateTime.now();
    final db = _repository.database;

    switch (tableName) {
      case 'task':
        final projectLocalId = await _resolveLocalId(
          'project',
          remoteRecord,
          'projectSupabaseId',
        );
        if (projectLocalId == null) break;
        
        final parentTaskLocalId = await _resolveLocalId(
          'task',
          remoteRecord,
          'parentTaskSupabaseId',
        );

        await db.into(db.task).insert(
          TaskCompanion(
            name: Value(remoteRecord['name'] as String),
            projectId: Value(projectLocalId),
            unit: Value(remoteRecord['unit'] as String?),
            startPoint: Value(remoteRecord['start_point'] as int? ?? 0),
            current: Value(remoteRecord['current'] as int? ?? 0),
            endGoal: Value(remoteRecord['end_goal'] as int? ?? 1),
            deadline: Value(SyncConverter.parseDateTime(remoteRecord['deadline'])),
            isCompleted: Value(remoteRecord['is_completed'] as bool? ?? false),
            completedAt: Value(SyncConverter.parseDateTime(remoteRecord['completed_at'])),
            parentTaskId: Value(parentTaskLocalId),
            orderIndex: Value(remoteRecord['order_index'] as int? ?? 0),
            depth: Value(remoteRecord['depth'] as int? ?? 0),
            supabaseId: Value(remoteRecord['supabase_id'] as String),
            lastModified: Value(SyncConverter.parseDateTime(remoteRecord['last_modified']) ?? now),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;

      case 'project':
        final parentProjectLocalId = await _resolveLocalId(
          'project',
          remoteRecord,
          'parentProjectSupabaseId',
        );
        final categoryLocalId = await _resolveLocalId(
          'project_category',
          remoteRecord,
          'categorySupabaseId',
        );

        await db.into(db.project).insert(
          ProjectCompanion(
            parentProjectId: Value(parentProjectLocalId),
            name: Value(remoteRecord['name'] as String),
            startDate: Value(SyncConverter.parseDateTime(remoteRecord['start_date'])!),
            deadline: Value(SyncConverter.parseDateTime(remoteRecord['deadline'])!),
            startPoint: Value(remoteRecord['start_point'] as int? ?? 0),
            current: Value(remoteRecord['current'] as int? ?? 0),
            goal: Value(remoteRecord['goal'] as int? ?? 1),
            unit: Value(remoteRecord['unit'] as String? ?? ""),
            category: Value(categoryLocalId),
            color: Value(SyncConverter.restoreUnsignedColor(remoteRecord['color'])),
            supabaseId: Value(remoteRecord['supabase_id'] as String),
            lastModified: Value(SyncConverter.parseDateTime(remoteRecord['last_modified']) ?? now),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;

      case 'project_category':
        await db.into(db.projectCategory).insert(
          ProjectCategoryCompanion(
            title: Value(remoteRecord['title'] as String?),
            iconCodePoint: Value(remoteRecord['icon_code_point'] as int?),
            orderIndex: Value(remoteRecord['order_index'] as int?),
            supabaseId: Value(remoteRecord['supabase_id'] as String),
            lastModified: Value(SyncConverter.parseDateTime(remoteRecord['last_modified']) ?? now),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;

      case 'block':
        final projectLocalId = await _resolveLocalId(
          'project',
          remoteRecord,
          'projectSupabaseId',
        );
        if (projectLocalId == null) break;

        await db.into(db.block).insert(
          BlockCompanion(
            projectId: Value(projectLocalId),
            dayLocal: Value(SyncConverter.parseDateTime(remoteRecord['day_local'])!),
            startMinuteOfDay: Value(remoteRecord['start_minute_of_day'] as int),
            lengthMinutes: Value(remoteRecord['length_minutes'] as int),
            supabaseId: Value(remoteRecord['supabase_id'] as String),
            lastModified: Value(SyncConverter.parseDateTime(remoteRecord['last_modified']) ?? now),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;

      case 'task_completion':
        final taskLocalId = await _resolveLocalId(
          'task',
          remoteRecord,
          'taskSupabaseId',
        );
        if (taskLocalId == null) break;

        await db.into(db.taskCompletion).insert(
          TaskCompletionCompanion(
            taskId: Value(taskLocalId),
            count: Value(remoteRecord['count'] as int),
            completedAt: Value(SyncConverter.parseDateTime(remoteRecord['completed_at'])!),
            supabaseId: Value(remoteRecord['supabase_id'] as String),
            lastModified: Value(SyncConverter.parseDateTime(remoteRecord['last_modified']) ?? now),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;

      case 'block_completion':
        final blockLocalId = await _resolveLocalId(
          'block',
          remoteRecord,
          'blockSupabaseId',
        );
        if (blockLocalId == null) break;

        await db.into(db.blockCompletion).insert(
          BlockCompletionCompanion(
            blockId: Value(blockLocalId),
            count: Value(remoteRecord['count'] as int),
            completedAt: Value(SyncConverter.parseDateTime(remoteRecord['completed_at'])!),
            supabaseId: Value(remoteRecord['supabase_id'] as String),
            lastModified: Value(SyncConverter.parseDateTime(remoteRecord['last_modified']) ?? now),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;

      case 'block_task':
        final blockLocalId = await _resolveLocalId(
          'block',
          remoteRecord,
          'blockSupabaseId',
        );
        final taskLocalId = await _resolveLocalId(
          'task',
          remoteRecord,
          'taskSupabaseId',
        );
        if (blockLocalId == null || taskLocalId == null) break;

        await db.into(db.blockTask).insert(
          BlockTaskCompanion(
            blockId: Value(blockLocalId),
            taskId: Value(taskLocalId),
            supabaseId: Value(remoteRecord['supabase_id'] as String),
            lastModified: Value(SyncConverter.parseDateTime(remoteRecord['last_modified']) ?? now),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;

      case 'settings':
        await db.into(db.settings).insert(
          SettingsCompanion(
            id: const Value(1),
            defaultStartTime: Value(remoteRecord['default_start_time'] as int),
            defaultTaskLength: Value(remoteRecord['default_task_length'] as int),
            defaultBreakTime: Value(remoteRecord['default_break_time'] as int),
            supabaseId: Value(remoteRecord['supabase_id'] as String),
            lastModified: Value(SyncConverter.parseDateTime(remoteRecord['last_modified']) ?? now),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;

      default:
    }
  }

  /// Update local record with remote data
  Future<void> _updateLocalWithRemote(
    String tableName,
    int localId,
    Map<String, dynamic> remoteRecord,
  ) async {
    final now = DateTime.now();
    final db = _repository.database;

    switch (tableName) {
      case 'task':
        final projectLocalId = await _resolveLocalId(
          'project',
          remoteRecord,
          'projectSupabaseId',
        );
        if (projectLocalId == null) break;
        
        final parentTaskLocalId = await _resolveLocalId(
          'task',
          remoteRecord,
          'parentTaskSupabaseId',
        );

        await (db.update(db.task)..where((t) => t.id.equals(localId))).write(
          TaskCompanion(
            name: Value(remoteRecord['name'] as String),
            projectId: Value(projectLocalId),
            unit: Value(remoteRecord['unit'] as String?),
            startPoint: Value(remoteRecord['start_point'] as int? ?? 0),
            current: Value(remoteRecord['current'] as int? ?? 0),
            endGoal: Value(remoteRecord['end_goal'] as int? ?? 1),
            deadline: Value(SyncConverter.parseDateTime(remoteRecord['deadline'])),
            isCompleted: Value(remoteRecord['is_completed'] as bool? ?? false),
            completedAt: Value(SyncConverter.parseDateTime(remoteRecord['completed_at'])),
            parentTaskId: Value(parentTaskLocalId),
            orderIndex: Value(remoteRecord['order_index'] as int? ?? 0),
            depth: Value(remoteRecord['depth'] as int? ?? 0),
            lastModified: Value(SyncConverter.parseDateTime(remoteRecord['last_modified']) ?? now),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;

      case 'project':
        final parentProjectLocalId = await _resolveLocalId(
          'project',
          remoteRecord,
          'parentProjectSupabaseId',
        );
        final categoryLocalId = await _resolveLocalId(
          'project_category',
          remoteRecord,
          'categorySupabaseId',
        );

        await (db.update(db.project)..where((p) => p.id.equals(localId))).write(
          ProjectCompanion(
            parentProjectId: Value(parentProjectLocalId),
            name: Value(remoteRecord['name'] as String),
            startDate: Value(SyncConverter.parseDateTime(remoteRecord['start_date'])!),
            deadline: Value(SyncConverter.parseDateTime(remoteRecord['deadline'])!),
            startPoint: Value(remoteRecord['start_point'] as int? ?? 0),
            current: Value(remoteRecord['current'] as int? ?? 0),
            goal: Value(remoteRecord['goal'] as int? ?? 1),
            unit: Value(remoteRecord['unit'] as String? ?? ""),
            category: Value(categoryLocalId),
            color: Value(SyncConverter.restoreUnsignedColor(remoteRecord['color'])),
            lastModified: Value(SyncConverter.parseDateTime(remoteRecord['last_modified']) ?? now),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;

      case 'project_category':
        await (db.update(db.projectCategory)..where((pc) => pc.id.equals(localId))).write(
          ProjectCategoryCompanion(
            title: Value(remoteRecord['title'] as String?),
            iconCodePoint: Value(remoteRecord['icon_code_point'] as int?),
            orderIndex: Value(remoteRecord['order_index'] as int?),
            lastModified: Value(SyncConverter.parseDateTime(remoteRecord['last_modified']) ?? now),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;

      case 'block':
        final projectLocalId = await _resolveLocalId(
          'project',
          remoteRecord,
          'projectSupabaseId',
        );
        if (projectLocalId == null) break;

        await (db.update(db.block)..where((b) => b.id.equals(localId))).write(
          BlockCompanion(
            projectId: Value(projectLocalId),
            dayLocal: Value(SyncConverter.parseDateTime(remoteRecord['day_local'])!),
            startMinuteOfDay: Value(remoteRecord['start_minute_of_day'] as int),
            lengthMinutes: Value(remoteRecord['length_minutes'] as int),
            lastModified: Value(SyncConverter.parseDateTime(remoteRecord['last_modified']) ?? now),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;

      case 'task_completion':
        final taskLocalId = await _resolveLocalId(
          'task',
          remoteRecord,
          'taskSupabaseId',
        );
        if (taskLocalId == null) break;

        await (db.update(db.taskCompletion)..where((tc) => tc.id.equals(localId))).write(
          TaskCompletionCompanion(
            taskId: Value(taskLocalId),
            count: Value(remoteRecord['count'] as int),
            completedAt: Value(SyncConverter.parseDateTime(remoteRecord['completed_at'])!),
            lastModified: Value(SyncConverter.parseDateTime(remoteRecord['last_modified']) ?? now),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;

      case 'block_completion':
        final blockLocalId = await _resolveLocalId(
          'block',
          remoteRecord,
          'blockSupabaseId',
        );
        if (blockLocalId == null) break;

        await (db.update(db.blockCompletion)..where((bc) => bc.id.equals(localId))).write(
          BlockCompletionCompanion(
            blockId: Value(blockLocalId),
            count: Value(remoteRecord['count'] as int),
            completedAt: Value(SyncConverter.parseDateTime(remoteRecord['completed_at'])!),
            lastModified: Value(SyncConverter.parseDateTime(remoteRecord['last_modified']) ?? now),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;

      case 'block_task':
        final blockLocalId = await _resolveLocalId(
          'block',
          remoteRecord,
          'blockSupabaseId',
        );
        final taskLocalId = await _resolveLocalId(
          'task',
          remoteRecord,
          'taskSupabaseId',
        );
        if (blockLocalId == null || taskLocalId == null) break;

        await (db.update(db.blockTask)
              ..where((bt) =>
                  bt.blockId.equals(blockLocalId) & bt.taskId.equals(taskLocalId)))
            .write(
              BlockTaskCompanion(
                lastModified: Value(SyncConverter.parseDateTime(remoteRecord['last_modified']) ?? now),
                needsSync: const Value(false),
                isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
                version: Value(remoteRecord['version'] as int? ?? 1),
              ),
            );
        break;

      case 'settings':
        await (db.update(db.settings)..where((s) => s.id.equals(localId))).write(
          SettingsCompanion(
            defaultStartTime: Value(remoteRecord['default_start_time'] as int),
            defaultTaskLength: Value(remoteRecord['default_task_length'] as int),
            defaultBreakTime: Value(remoteRecord['default_break_time'] as int),
            lastModified: Value(SyncConverter.parseDateTime(remoteRecord['last_modified']) ?? now),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;

      default:
    }
  }

  /// Resolve local ID from remote record
  Future<int?> _resolveLocalId(
    String tableName,
    Map<String, dynamic> remoteRecord,
    String remoteCamelCaseKey,
  ) async {
    final supabaseId = SyncConverter.getField<String>(remoteRecord, remoteCamelCaseKey);
    return _repository.getLocalIdForSupabase(tableName, supabaseId);
  }
}
