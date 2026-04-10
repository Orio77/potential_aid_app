import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/services/sync_repository.dart';
import 'package:potential_aid_app/utils/sync_converter.dart';

/// Handles inserting remote records into the local database.
class SyncRecordInserter {
  final SyncRepository _repository;

  SyncRecordInserter(this._repository);

  Future<void> insert(
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
            defaultTimelineProjectId: Value(
              remoteRecord['default_timeline_project_id'] as int?,
            ),
            defaultTimelineCategoryId: Value(
              remoteRecord['default_timeline_category_id'] as int?,
            ),
            defaultTimelineShowProjects: Value(
              remoteRecord['default_timeline_show_projects'] as bool? ?? true,
            ),
            defaultTimelineUncompletedOnly: Value(
              remoteRecord['default_timeline_uncompleted_only'] as bool? ?? true,
            ),
            pursuitStateJson: Value(remoteRecord['pursuit_state_json'] as String?),
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

  Future<int?> _resolveLocalId(
    String tableName,
    Map<String, dynamic> remoteRecord,
    String remoteCamelCaseKey,
  ) async {
    final supabaseId = SyncConverter.getField<String>(remoteRecord, remoteCamelCaseKey);
    return _repository.getLocalIdForSupabase(tableName, supabaseId);
  }
}
