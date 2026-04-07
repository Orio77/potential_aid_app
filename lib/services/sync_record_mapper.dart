import 'package:potential_aid_app/services/supabase_service.dart';
import 'package:potential_aid_app/services/sync_record_inserter.dart';
import 'package:potential_aid_app/services/sync_record_updater.dart';
import 'package:potential_aid_app/services/sync_repository.dart';
import 'package:potential_aid_app/utils/sync_converter.dart';

/// Handles complex record mapping and conversion between local and remote formats.
/// Insert/update logic is delegated to [SyncRecordInserter] and [SyncRecordUpdater].
class SyncRecordMapper {
  final SyncRepository _repository;
  final SupabaseService _supabaseService;
  late final SyncRecordInserter _inserter;
  late final SyncRecordUpdater _updater;

  SyncRecordMapper(this._repository, this._supabaseService) {
    _inserter = SyncRecordInserter(_repository);
    _updater = SyncRecordUpdater(_repository);
  }

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
      if (key == 'needsSync') {
        return; // local-only flag, must never be pushed to remote
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
  ///
  /// Conflict Resolution Strategy:
  /// 1. No local record exists → Insert remote record (unless deleted)
  /// 2. Remote record is deleted → Delete local record
  /// 3. Local has pending changes (needsSync=true):
  ///    - Use version-based resolution (higher version wins)
  ///    - If versions equal, use timestamp (more recent wins)
  /// 4. Local has no pending changes → Apply remote changes
  Future<void> applyRemoteChangeToLocal(
    String tableName,
    Map<String, dynamic> remoteRecord,
  ) async {
    try {
      final supabaseId = remoteRecord['supabase_id'] as String?;
      if (supabaseId == null) return;

      final existingLocal = await _repository.findLocalRecordBySupabaseId(
        tableName,
        supabaseId,
      );

      final remoteModified = SyncConverter.parseDateTime(
        remoteRecord['last_modified'],
      );
      final remoteVersion = remoteRecord['version'] as int? ?? 1;
      final isRemoteDeleted =
          remoteRecord['is_deleted'] == true || remoteRecord['is_deleted'] == 1;

      if (existingLocal == null) {
        if (!isRemoteDeleted) {
          await _inserter.insert(tableName, remoteRecord);
        }
        return;
      }

      final localModified = existingLocal['last_modified'] as DateTime?;
      final localVersion = existingLocal['version'] as int? ?? 1;
      final localNeedsSync = existingLocal['needs_sync'] as bool? ?? false;
      final requiresLocalId = tableName != 'block_task';
      final int? localId = requiresLocalId ? existingLocal['id'] as int? : null;

      if (requiresLocalId && localId == null) return;

      if (isRemoteDeleted) {
        if (tableName == 'block_task') {
          await _repository.deleteBlockTaskBySupabaseId(supabaseId);
        } else {
          await _repository.deleteLocalRecordsByIds(tableName, [localId!]);
        }
        return;
      }

      if (localNeedsSync) {
        if (remoteVersion > localVersion) {
          await _updater.update(
            tableName,
            tableName == 'block_task' ? 0 : localId!,
            remoteRecord,
          );
        } else if (remoteVersion == localVersion) {
          if (remoteModified != null && localModified != null) {
            if (remoteModified.isAfter(localModified)) {
              await _updater.update(
                tableName,
                tableName == 'block_task' ? 0 : localId!,
                remoteRecord,
              );
            }
          } else {
            await _updater.update(
              tableName,
              tableName == 'block_task' ? 0 : localId!,
              remoteRecord,
            );
          }
        }
        // remoteVersion < localVersion: keep local (do nothing)
      } else {
        await _updater.update(
          tableName,
          tableName == 'block_task' ? 0 : localId!,
          remoteRecord,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

}
