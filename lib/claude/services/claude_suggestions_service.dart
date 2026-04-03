import 'package:drift/drift.dart';
import 'package:potential_aid_app/claude/models/claude_suggestion.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/services/supabase_service.dart';
import 'package:potential_aid_app/utils/sync_converter.dart';

class ClaudeSuggestionsService {
  final AppDatabase _db;

  ClaudeSuggestionsService(this._db);

  SupabaseService get _supabase => SupabaseService.instance;

  /// Fetch all pending suggestions from Supabase.
  Future<List<ClaudeSuggestion>> fetchPending() async {
    final rows = await _supabase.client
        .from('claude_suggestions')
        .select()
        .eq('status', 'pending')
        .order('created_at');
    return (rows as List).map((r) => ClaudeSuggestion.fromJson(r)).toList();
  }

  /// Mark a suggestion as rejected without applying it.
  Future<void> reject(String suggestionId) async {
    await _supabase.client
        .from('claude_suggestions')
        .update({'status': 'rejected'})
        .eq('id', suggestionId);
  }

  /// Accept a suggestion: apply the payload to the local DB, then mark accepted.
  Future<void> accept(ClaudeSuggestion s) async {
    await _applyToLocalDb(s);
    await _supabase.client
        .from('claude_suggestions')
        .update({'status': 'accepted'})
        .eq('id', s.id);
  }

  // ── Apply helpers ──────────────────────────────────────────────────────────

  Future<void> _applyToLocalDb(ClaudeSuggestion s) async {
    final p = s.payload;
    final now = DateTime.now();

    switch (s.tableName) {
      case 'task':
        if (s.operation == 'update' && s.recordSupabaseId != null) {
          await _updateTask(s.recordSupabaseId!, p, now);
        } else if (s.operation == 'insert') {
          await _insertTask(p, now);
        }
      case 'project':
        if (s.operation == 'update' && s.recordSupabaseId != null) {
          await _updateProject(s.recordSupabaseId!, p, now);
        }
      case 'task_completion':
        if (s.operation == 'insert') {
          await _insertTaskCompletion(p, now);
        }
      case 'project_category':
        if (s.operation == 'update' && s.recordSupabaseId != null) {
          await _updateCategory(s.recordSupabaseId!, p, now);
        }
    }
  }

  // ── Task ──────────────────────────────────────────────────────────────────

  Future<void> _updateTask(
    String supabaseId,
    Map<String, dynamic> p,
    DateTime now,
  ) async {
    final existing = await (
      _db.select(_db.task)..where((t) => t.supabaseId.equals(supabaseId))
    ).getSingleOrNull();
    if (existing == null) return;

    final companion = TaskCompanion(
      name: p.containsKey('name') ? Value(p['name'] as String) : const Value.absent(),
      deadline: p.containsKey('deadline')
          ? Value(SyncConverter.parseDateTime(p['deadline']))
          : const Value.absent(),
      isCompleted: p.containsKey('is_completed')
          ? Value(p['is_completed'] as bool)
          : const Value.absent(),
      completedAt: p.containsKey('completed_at')
          ? Value(SyncConverter.parseDateTime(p['completed_at']))
          : const Value.absent(),
      current: p.containsKey('current')
          ? Value(p['current'] as int)
          : const Value.absent(),
      endGoal: p.containsKey('end_goal')
          ? Value(p['end_goal'] as int)
          : const Value.absent(),
      unit: p.containsKey('unit')
          ? Value(p['unit'] as String?)
          : const Value.absent(),
      orderIndex: p.containsKey('order_index')
          ? Value(p['order_index'] as int)
          : const Value.absent(),
      needsSync: const Value(true),
      lastModified: Value(now),
      version: Value(existing.version + 1),
    );

    await (_db.update(_db.task)..where((t) => t.id.equals(existing.id)))
        .write(companion);
  }

  Future<void> _insertTask(Map<String, dynamic> p, DateTime now) async {
    final projectId = await _resolveLocalId('project', p['project_supabase_id'] as String?);
    if (projectId == null) return;

    final parentId = await _resolveLocalId('task', p['parent_task_supabase_id'] as String?);

    await _db.into(_db.task).insert(
      TaskCompanion.insert(
        name: p['name'] as String,
        projectId: projectId,
        unit: Value(p['unit'] as String?),
        startPoint: Value(p['start_point'] as int? ?? 0),
        current: Value(p['current'] as int? ?? 0),
        endGoal: Value(p['end_goal'] as int? ?? 1),
        deadline: Value(SyncConverter.parseDateTime(p['deadline'])),
        isCompleted: Value(p['is_completed'] as bool? ?? false),
        parentTaskId: Value(parentId),
        orderIndex: Value(p['order_index'] as int? ?? 0),
        depth: Value(p['depth'] as int? ?? 0),
        needsSync: const Value(true),
        lastModified: now,
        version: const Value(1),
      ),
    );
  }

  // ── Project ───────────────────────────────────────────────────────────────

  Future<void> _updateProject(
    String supabaseId,
    Map<String, dynamic> p,
    DateTime now,
  ) async {
    final existing = await (
      _db.select(_db.project)..where((pr) => pr.supabaseId.equals(supabaseId))
    ).getSingleOrNull();
    if (existing == null) return;

    final companion = ProjectCompanion(
      name: p.containsKey('name') ? Value(p['name'] as String) : const Value.absent(),
      deadline: p.containsKey('deadline')
          ? Value(SyncConverter.parseDateTime(p['deadline'])!)
          : const Value.absent(),
      startDate: p.containsKey('start_date')
          ? Value(SyncConverter.parseDateTime(p['start_date'])!)
          : const Value.absent(),
      goal: p.containsKey('goal') ? Value(p['goal'] as int) : const Value.absent(),
      current: p.containsKey('current') ? Value(p['current'] as int) : const Value.absent(),
      unit: p.containsKey('unit') ? Value(p['unit'] as String) : const Value.absent(),
      needsSync: const Value(true),
      lastModified: Value(now),
      version: Value(existing.version + 1),
    );

    await (_db.update(_db.project)..where((pr) => pr.id.equals(existing.id)))
        .write(companion);
  }

  // ── TaskCompletion ────────────────────────────────────────────────────────

  Future<void> _insertTaskCompletion(Map<String, dynamic> p, DateTime now) async {
    final taskId = await _resolveLocalId('task', p['task_supabase_id'] as String?);
    if (taskId == null) return;

    await _db.into(_db.taskCompletion).insert(
      TaskCompletionCompanion.insert(
        taskId: taskId,
        count: p['count'] as int,
        completedAt:
            SyncConverter.parseDateTime(p['completed_at']) ?? now,
        needsSync: const Value(true),
        lastModified: now,
        version: const Value(1),
      ),
    );
  }

  // ── ProjectCategory ───────────────────────────────────────────────────────

  Future<void> _updateCategory(
    String supabaseId,
    Map<String, dynamic> p,
    DateTime now,
  ) async {
    final existing = await (
      _db.select(_db.projectCategory)
        ..where((c) => c.supabaseId.equals(supabaseId))
    ).getSingleOrNull();
    if (existing == null) return;

    final companion = ProjectCategoryCompanion(
      title: p.containsKey('title') ? Value(p['title'] as String?) : const Value.absent(),
      orderIndex: p.containsKey('order_index') ? Value(p['order_index'] as int?) : const Value.absent(),
      needsSync: const Value(true),
      lastModified: Value(now),
      version: Value(existing.version + 1),
    );

    await (_db.update(_db.projectCategory)
          ..where((c) => c.id.equals(existing.id)))
        .write(companion);
  }

  // ── FK helper ─────────────────────────────────────────────────────────────

  Future<int?> _resolveLocalId(String table, String? supabaseId) async {
    if (supabaseId == null) return null;
    switch (table) {
      case 'project':
        return (await (_db.select(_db.project)
                  ..where((p) => p.supabaseId.equals(supabaseId)))
                .getSingleOrNull())
            ?.id;
      case 'task':
        return (await (_db.select(_db.task)
                  ..where((t) => t.supabaseId.equals(supabaseId)))
                .getSingleOrNull())
            ?.id;
      default:
        return null;
    }
  }
}
