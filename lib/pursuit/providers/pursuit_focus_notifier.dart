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

  Future<void> _load() async {
    final row =
        await (_db.select(_db.settings)..where((s) => s.id.equals(1)))
            .getSingleOrNull();
    final raw = PursuitFocusState.tryParse(row?.pursuitStateJson);
    final base = raw ?? PursuitFocusState.initial();
    final cleaned = await _validateAgainstDb(base);
    state = cleaned;
    if (raw != null && !_structurallyEqual(raw, cleaned)) {
      await _persist(cleaned);
    }
  }

  bool _structurallyEqual(PursuitFocusState a, PursuitFocusState b) {
    if (a.slots.toString() != b.slots.toString()) return false;
    if (a.projectQueue.toString() != b.projectQueue.toString()) return false;
    if (a.taskQueues.length != b.taskQueues.length) return false;
    for (final e in a.taskQueues.entries) {
      if (b.taskQueues[e.key]?.toString() != e.value.toString()) return false;
    }
    return true;
  }

  Future<PursuitFocusState> _validateAgainstDb(PursuitFocusState s) async {
    final slots = List<int?>.from(s.slots);
    for (var i = 0; i < PursuitFocusState.slotCount; i++) {
      final id = slots[i];
      if (id == null) continue;
      final p = await _db.projectDao.getProjectById(id);
      if (p == null || p.isDeleted) slots[i] = null;
    }

    final slotSet = slots.whereType<int>().toSet();
    final projectQueue = <int>[];
    for (final id in s.projectQueue) {
      if (slotSet.contains(id)) continue;
      final p = await _db.projectDao.getProjectById(id);
      if (p == null || p.isDeleted) continue;
      if (!projectQueue.contains(id)) projectQueue.add(id);
    }

    final taskQueues = <int, List<int>>{};
    for (final e in s.taskQueues.entries) {
      final pid = e.key;
      if (!slotSet.contains(pid) && !projectQueue.contains(pid)) {
        continue;
      }
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
        if (t.isDeleted || t.projectId != pid || t.isCompleted) {
          continue;
        }
        if (!kept.contains(tid)) kept.add(tid);
      }
      if (kept.isNotEmpty) taskQueues[pid] = kept;
    }

    return PursuitFocusState(
      slots: slots,
      projectQueue: projectQueue,
      taskQueues: taskQueues,
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
      ),
    );
    state = next;
  }

  Future<void> reload() => _load();

  /// After [projectId]'s progress changes: if it hits goal while in a slot,
  /// clear that slot and promote the next project from the queue into it.
  Future<void> onProjectProgressChanged(int projectId) async {
    await _load();
    final p = await _db.projectDao.getProjectById(projectId);
    if (p == null || p.isDeleted) return;
    if (p.current < p.goal) return;

    final slotIdx = state.slots.indexWhere((id) => id == projectId);
    if (slotIdx < 0) return;

    final newSlots = List<int?>.from(state.slots);
    newSlots[slotIdx] = null;

    final newQueue = List<int>.from(state.projectQueue);
    final next = _takeNextFromQueue(newQueue, newSlots);
    if (next != null) {
      newSlots[slotIdx] = next;
    }

    await _persist(
      state.copyWith(slots: newSlots, projectQueue: newQueue),
    );
  }

  int? _takeNextFromQueue(List<int> queue, List<int?> slots) {
    while (queue.isNotEmpty) {
      final id = queue.removeAt(0);
      if (!slots.contains(id)) return id;
    }
    return null;
  }

  /// When [taskId] completes: if it is the head of that project's queue, pop it.
  Future<void> onTaskCompleted(int taskId, int projectId) async {
    await _load();
    final q = state.taskQueues[projectId];
    if (q == null || q.isEmpty) return;
    if (q.first != taskId) return;

    final rest = List<int>.from(q)..removeAt(0);
    final newMap = Map<int, List<int>>.from(state.taskQueues);
    if (rest.isEmpty) {
      newMap.remove(projectId);
    } else {
      newMap[projectId] = rest;
    }
    await _persist(state.copyWith(taskQueues: newMap));
  }

  Future<void> setSlot(int index, int? projectId) async {
    if (index < 0 || index >= PursuitFocusState.slotCount) return;
    await _load();

    var next = state.copyWith();
    final slots = List<int?>.from(next.slots);
    final queue = List<int>.from(next.projectQueue);

    if (projectId != null) {
      final p = await _db.projectDao.getProjectById(projectId);
      if (p == null || p.isDeleted) return;

      for (var i = 0; i < slots.length; i++) {
        if (slots[i] == projectId) slots[i] = null;
      }
      queue.remove(projectId);
      slots[index] = projectId;
    } else {
      slots[index] = null;
    }

    next = next.copyWith(slots: slots, projectQueue: queue);
    await _persist(await _validateAgainstDb(next));
  }

  Future<void> addProjectToBacklog(int projectId) async {
    final p = await _db.projectDao.getProjectById(projectId);
    if (p == null || p.isDeleted) return;

    await _load();
    final slots = state.slots;
    if (slots.contains(projectId)) return;
    final queue = List<int>.from(state.projectQueue);
    if (queue.contains(projectId)) return;
    queue.add(projectId);
    await _persist(state.copyWith(projectQueue: queue));
  }

  Future<void> removeProjectFromBacklogAt(int index) async {
    await _load();
    final queue = List<int>.from(state.projectQueue);
    if (index < 0 || index >= queue.length) return;
    queue.removeAt(index);
    await _persist(state.copyWith(projectQueue: queue));
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
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = queue.removeAt(oldIndex);
    queue.insert(newIndex, item);
    await _persist(state.copyWith(projectQueue: queue));
  }

  Future<void> addTaskToQueue(int projectId, int taskId) async {
    final TaskData t;
    try {
      t = await _db.taskDao.getTaskById(taskId);
    } catch (_) {
      return;
    }
    if (t.isDeleted || t.projectId != projectId || t.isCompleted) {
      return;
    }

    await _load();
    final slots = state.slots;
    final queue = state.projectQueue;
    if (!slots.contains(projectId) && !queue.contains(projectId)) {
      return;
    }

    final map = Map<int, List<int>>.from(state.taskQueues);
    final list = List<int>.from(map[projectId] ?? []);
    if (list.contains(taskId)) return;
    list.add(taskId);
    map[projectId] = list;
    await _persist(state.copyWith(taskQueues: map));
  }

  Future<void> removeTaskFromQueueAt(int projectId, int index) async {
    await _load();
    final map = Map<int, List<int>>.from(state.taskQueues);
    final list = List<int>.from(map[projectId] ?? []);
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    if (list.isEmpty) {
      map.remove(projectId);
    } else {
      map[projectId] = list;
    }
    await _persist(state.copyWith(taskQueues: map));
  }

  Future<void> reorderTaskQueue(int projectId, int oldIndex, int newIndex) async {
    await _load();
    final map = Map<int, List<int>>.from(state.taskQueues);
    final list = List<int>.from(map[projectId] ?? []);
    if (oldIndex < 0 ||
        oldIndex >= list.length ||
        newIndex < 0 ||
        newIndex > list.length) {
      return;
    }
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    map[projectId] = list;
    await _persist(state.copyWith(taskQueues: map));
  }
}

final pursuitFocusNotifierProvider =
    StateNotifierProvider<PursuitFocusNotifier, PursuitFocusState>((ref) {
      return PursuitFocusNotifier(ref);
    });
