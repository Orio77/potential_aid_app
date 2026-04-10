import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/pursuit/models/pursuit_focus_state.dart';
import 'package:potential_aid_app/providers/database_provider.dart';

class PursuitFocusNotifier extends StateNotifier<PursuitFocusState> {
  PursuitFocusNotifier(this._ref) : super(PursuitFocusState.initial()) {
    _load();
  }

  final Ref _ref;

  AppDatabase get _db => _ref.read(databaseProvider);

  // ── Load / persist ──────────────────────────────────────────────────────────

  Future<void> _load() async {
    final row =
        await (_db.select(_db.settings)..where((s) => s.id.equals(1)))
            .getSingleOrNull();
    final raw = PursuitFocusState.tryParse(row?.pursuitStateJson);
    final base = raw ?? PursuitFocusState.initial();
    final cleaned = await _validateAgainstDb(base);
    if (!mounted) return;
    state = cleaned;
    if (raw != null && !_equal(raw, cleaned)) {
      await _persist(cleaned);
    }
  }

  bool _equal(PursuitFocusState a, PursuitFocusState b) {
    if (a.slots.toString() != b.slots.toString()) return false;
    if (a.projectQueue.toString() != b.projectQueue.toString()) return false;
    if (a.unifiedTaskOrder.toString() != b.unifiedTaskOrder.toString()) {
      return false;
    }
    if (a.taskQueues.length != b.taskQueues.length) return false;
    for (final e in a.taskQueues.entries) {
      if (b.taskQueues[e.key]?.toString() != e.value.toString()) return false;
    }
    return true;
  }

  Future<PursuitFocusState> _validateAgainstDb(PursuitFocusState s) async {
    // Validate slots
    final slots = List<int?>.from(s.slots);
    for (var i = 0; i < PursuitFocusState.slotCount; i++) {
      final id = slots[i];
      if (id == null) continue;
      final p = await _db.projectDao.getProjectById(id);
      if (p == null || p.isDeleted) slots[i] = null;
    }

    // Validate project queue (no duplicates, not already in slots)
    final slotSet = slots.whereType<int>().toSet();
    final projectQueue = <int>[];
    for (final id in s.projectQueue) {
      if (slotSet.contains(id)) continue;
      final p = await _db.projectDao.getProjectById(id);
      if (p == null || p.isDeleted) continue;
      if (!projectQueue.contains(id)) projectQueue.add(id);
    }

    // Validate per-project task queues
    final allProjectIds = {...slotSet, ...projectQueue};
    final taskQueues = <int, List<int>>{};
    for (final e in s.taskQueues.entries) {
      final pid = e.key;
      if (!allProjectIds.contains(pid)) continue;
      final p = await _db.projectDao.getProjectById(pid);
      if (p == null || p.isDeleted) continue;

      final kept = <int>[];
      for (final tid in e.value) {
        TaskData t;
        try {
          t = await _db.taskDao.getTaskById(tid);
        } catch (_) {
          continue;
        }
        if (t.isDeleted || t.projectId != pid || t.isCompleted) continue;
        if (!kept.contains(tid)) kept.add(tid);
      }
      if (kept.isNotEmpty) taskQueues[pid] = kept;
    }

    // Sync unified task order with validated task queues
    final validIds = taskQueues.values.expand((l) => l).toSet();
    final cleanedUto = <int>[];
    for (final tid in s.unifiedTaskOrder) {
      if (validIds.contains(tid) && !cleanedUto.contains(tid)) {
        cleanedUto.add(tid);
      }
    }
    // Append tasks in queues not yet in unified order
    for (final tid in validIds) {
      if (!cleanedUto.contains(tid)) cleanedUto.add(tid);
    }

    return PursuitFocusState(
      slots: slots,
      projectQueue: projectQueue,
      taskQueues: taskQueues,
      unifiedTaskOrder: cleanedUto,
    );
  }

  Future<void> _persist(PursuitFocusState next) async {
    final row =
        await (_db.select(_db.settings)..where((s) => s.id.equals(1)))
            .getSingleOrNull();
    if (row == null) return;

    await (_db.update(_db.settings)..where((s) => s.id.equals(1))).write(
      SettingsCompanion(
        pursuitStateJson: Value(next.toJsonString()),
        lastModified: Value(DateTime.now()),
        needsSync: const Value(true),
      ),
    );
    if (mounted) state = next;
  }

  Future<void> reload() => _load();

  // ── Completion hooks ────────────────────────────────────────────────────────

  /// Project reached/exceeded its goal while in a slot: clear that slot and
  /// promote the next queued project into it.
  Future<void> onProjectProgressChanged(int projectId) async {
    await _load();
    final p = await _db.projectDao.getProjectById(projectId);
    if (p == null || p.isDeleted || p.current < p.goal) return;

    final slotIdx = state.slots.indexWhere((id) => id == projectId);
    if (slotIdx < 0) return;

    final newSlots = List<int?>.from(state.slots);
    newSlots[slotIdx] = null;

    // Remove all tasks of the completing project from unified order
    final removedTasks = state.taskQueues[projectId] ?? [];
    final newUto = List<int>.from(state.unifiedTaskOrder)
      ..removeWhere(removedTasks.contains);
    final newTaskQueues = Map<int, List<int>>.from(state.taskQueues)
      ..remove(projectId);

    final newQueue = List<int>.from(state.projectQueue);
    final next = _takeNextFromQueue(newQueue, newSlots);
    if (next != null) newSlots[slotIdx] = next;

    await _persist(state.copyWith(
      slots: newSlots,
      projectQueue: newQueue,
      taskQueues: newTaskQueues,
      unifiedTaskOrder: newUto,
    ));
  }

  int? _takeNextFromQueue(List<int> queue, List<int?> slots) {
    while (queue.isNotEmpty) {
      final id = queue.removeAt(0);
      if (!slots.contains(id)) return id;
    }
    return null;
  }

  /// Task completed: pop it from per-project queue head (if it was head) and
  /// from the unified task order.
  Future<void> onTaskCompleted(int taskId, int projectId) async {
    await _load();

    final newMap = Map<int, List<int>>.from(state.taskQueues);
    final q = List<int>.from(newMap[projectId] ?? []);
    if (q.isNotEmpty && q.first == taskId) q.removeAt(0);
    if (q.isEmpty) {
      newMap.remove(projectId);
    } else {
      newMap[projectId] = q;
    }

    final newUto = List<int>.from(state.unifiedTaskOrder)..remove(taskId);

    await _persist(state.copyWith(taskQueues: newMap, unifiedTaskOrder: newUto));
  }

  /// Batch-remove multiple completed tasks from the per-project queue and
  /// the unified task order. Used to clean up auto-completed descendants.
  Future<void> onTasksCompleted(List<int> taskIds, int projectId) async {
    if (taskIds.isEmpty) return;
    await _load();

    final idSet = taskIds.toSet();
    final newMap = Map<int, List<int>>.from(state.taskQueues);
    final q = List<int>.from(newMap[projectId] ?? []);
    q.removeWhere(idSet.contains);
    if (q.isEmpty) {
      newMap.remove(projectId);
    } else {
      newMap[projectId] = q;
    }

    final newUto = List<int>.from(state.unifiedTaskOrder)
      ..removeWhere(idSet.contains);

    await _persist(state.copyWith(taskQueues: newMap, unifiedTaskOrder: newUto));
  }

  // ── Slot management ─────────────────────────────────────────────────────────

  Future<void> setSlot(int index, int? projectId) async {
    if (index < 0 || index >= PursuitFocusState.slotCount) return;
    await _load();

    final slots = List<int?>.from(state.slots);
    final queue = List<int>.from(state.projectQueue);
    var taskQueues = Map<int, List<int>>.from(state.taskQueues);
    var uto = List<int>.from(state.unifiedTaskOrder);

    // Clear the old project in this slot, removing its tasks from unified order
    final oldPid = slots[index];
    if (oldPid != null) {
      final oldTasks = taskQueues[oldPid] ?? [];
      uto.removeWhere(oldTasks.contains);
      taskQueues.remove(oldPid);
    }

    if (projectId != null) {
      final p = await _db.projectDao.getProjectById(projectId);
      if (p == null || p.isDeleted) return;

      // Remove from other slots if already there
      for (var i = 0; i < slots.length; i++) {
        if (slots[i] == projectId) {
          final evictedTasks = taskQueues[projectId] ?? [];
          uto.removeWhere(evictedTasks.contains);
          taskQueues.remove(projectId);
          slots[i] = null;
        }
      }
      queue.remove(projectId);
      slots[index] = projectId;
    } else {
      slots[index] = null;
    }

    final next = state.copyWith(
      slots: slots,
      projectQueue: queue,
      taskQueues: taskQueues,
      unifiedTaskOrder: uto,
    );
    await _persist(await _validateAgainstDb(next));
  }

  // ── Project queue (backlog) management ──────────────────────────────────────

  Future<void> addProjectToBacklog(int projectId) async {
    final p = await _db.projectDao.getProjectById(projectId);
    if (p == null || p.isDeleted) return;
    await _load();
    if (state.slots.contains(projectId)) return;
    final queue = List<int>.from(state.projectQueue);
    if (queue.contains(projectId)) return;
    queue.add(projectId);
    await _persist(state.copyWith(projectQueue: queue));
  }

  Future<void> removeProjectFromBacklogAt(int index) async {
    await _load();
    final queue = List<int>.from(state.projectQueue);
    if (index < 0 || index >= queue.length) return;
    final pid = queue.removeAt(index);
    // Remove that project's tasks from unified order
    final tasks = state.taskQueues[pid] ?? [];
    final uto = List<int>.from(state.unifiedTaskOrder)
      ..removeWhere(tasks.contains);
    final tq = Map<int, List<int>>.from(state.taskQueues)..remove(pid);
    await _persist(state.copyWith(
      projectQueue: queue,
      taskQueues: tq,
      unifiedTaskOrder: uto,
    ));
  }

  Future<void> reorderBacklog(int oldIndex, int newIndex) async {
    await _load();
    final queue = List<int>.from(state.projectQueue);
    if (oldIndex < 0 ||
        oldIndex >= queue.length ||
        newIndex < 0 ||
        newIndex > queue.length) {
      return;
    }
    if (oldIndex < newIndex) newIndex -= 1;
    final item = queue.removeAt(oldIndex);
    queue.insert(newIndex, item);
    await _persist(state.copyWith(projectQueue: queue));
  }

  // ── Task queue management ───────────────────────────────────────────────────

  Future<void> addTaskToQueue(int projectId, int taskId) async {
    final TaskData t;
    try {
      t = await _db.taskDao.getTaskById(taskId);
    } catch (_) {
      return;
    }
    if (t.isDeleted || t.projectId != projectId || t.isCompleted) return;

    await _load();
    final allProjectIds = <int>{
      ...state.slots.whereType<int>(),
      ...state.projectQueue,
    };
    if (!allProjectIds.contains(projectId)) return;

    final tq = Map<int, List<int>>.from(state.taskQueues);
    final list = List<int>.from(tq[projectId] ?? []);
    if (list.contains(taskId)) return;
    list.add(taskId);
    tq[projectId] = list;

    final uto = List<int>.from(state.unifiedTaskOrder);
    if (!uto.contains(taskId)) uto.add(taskId);

    await _persist(state.copyWith(taskQueues: tq, unifiedTaskOrder: uto));
  }

  Future<void> removeTaskFromQueueAt(int projectId, int index) async {
    await _load();
    final tq = Map<int, List<int>>.from(state.taskQueues);
    final list = List<int>.from(tq[projectId] ?? []);
    if (index < 0 || index >= list.length) return;
    final tid = list.removeAt(index);
    if (list.isEmpty) {
      tq.remove(projectId);
    } else {
      tq[projectId] = list;
    }
    final uto = List<int>.from(state.unifiedTaskOrder)..remove(tid);
    await _persist(state.copyWith(taskQueues: tq, unifiedTaskOrder: uto));
  }

  Future<void> reorderTaskQueue(
      int projectId, int oldIndex, int newIndex) async {
    await _load();
    final tq = Map<int, List<int>>.from(state.taskQueues);
    final list = List<int>.from(tq[projectId] ?? []);
    if (oldIndex < 0 ||
        oldIndex >= list.length ||
        newIndex < 0 ||
        newIndex > list.length) {
      return;
    }
    if (oldIndex < newIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    tq[projectId] = list;
    await _persist(state.copyWith(taskQueues: tq));
  }

  /// Reorder the cross-project unified task list (task map view).
  Future<void> reorderUnifiedTasks(int oldIndex, int newIndex) async {
    await _load();
    final uto = List<int>.from(state.unifiedTaskOrder);
    if (oldIndex < 0 ||
        oldIndex >= uto.length ||
        newIndex < 0 ||
        newIndex > uto.length) {
      return;
    }
    if (oldIndex < newIndex) newIndex -= 1;
    final item = uto.removeAt(oldIndex);
    uto.insert(newIndex, item);
    await _persist(state.copyWith(unifiedTaskOrder: uto));
  }
}

final pursuitFocusNotifierProvider =
    StateNotifierProvider<PursuitFocusNotifier, PursuitFocusState>((ref) {
      return PursuitFocusNotifier(ref);
    });
