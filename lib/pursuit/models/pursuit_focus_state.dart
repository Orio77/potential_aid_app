import 'dart:convert';

/// Persisted pursuit focus: up to 3 active projects, a backlog queue,
/// per-project ordered task queues (FIFO auto-pop on complete), and a
/// unified cross-project task ordering used by the task map view.
class PursuitFocusState {
  static const int slotCount = 3;

  /// Exactly 3 entries; each holds a project id or null.
  final List<int?> slots;

  /// Projects waiting to fill a slot when one completes (FIFO).
  final List<int> projectQueue;

  /// Per-project task ids in FIFO order — head is auto-popped on completion.
  final Map<int, List<int>> taskQueues;

  /// Cross-project ordering of all queued tasks for the visual task map.
  /// Kept in sync with [taskQueues]: any task in a queue is here; order is
  /// user-defined across all three projects.
  final List<int> unifiedTaskOrder;

  const PursuitFocusState({
    required this.slots,
    required this.projectQueue,
    required this.taskQueues,
    required this.unifiedTaskOrder,
  });

  factory PursuitFocusState.initial() => PursuitFocusState(
        slots: List<int?>.filled(slotCount, null),
        projectQueue: [],
        taskQueues: {},
        unifiedTaskOrder: [],
      );

  PursuitFocusState copyWith({
    List<int?>? slots,
    List<int>? projectQueue,
    Map<int, List<int>>? taskQueues,
    List<int>? unifiedTaskOrder,
  }) {
    return PursuitFocusState(
      slots: slots ?? List<int?>.from(this.slots),
      projectQueue: projectQueue ?? List<int>.from(this.projectQueue),
      taskQueues: taskQueues != null
          ? Map<int, List<int>>.fromEntries(
              taskQueues.entries
                  .map((e) => MapEntry(e.key, List<int>.from(e.value))),
            )
          : Map<int, List<int>>.fromEntries(
              this.taskQueues.entries
                  .map((e) => MapEntry(e.key, List<int>.from(e.value))),
            ),
      unifiedTaskOrder:
          unifiedTaskOrder ?? List<int>.from(this.unifiedTaskOrder),
    );
  }

  factory PursuitFocusState.fromJson(Map<String, dynamic> json) {
    // Slots
    final slotList = json['slots'] as List<dynamic>?;
    final slots = List<int?>.filled(slotCount, null);
    if (slotList != null) {
      for (var i = 0; i < slotCount && i < slotList.length; i++) {
        final v = slotList[i];
        if (v is num) slots[i] = v.toInt();
      }
    }

    // Project queue
    final projectQueue = _parseIntList(json['projectQueue']);

    // Per-project task queues
    final tqRaw = json['taskQueues'] as Map<String, dynamic>?;
    final taskQueues = <int, List<int>>{};
    if (tqRaw != null) {
      for (final e in tqRaw.entries) {
        final pid = int.tryParse(e.key);
        if (pid == null) continue;
        final ids = _parseIntList(e.value);
        if (ids.isNotEmpty) taskQueues[pid] = ids;
      }
    }

    // Unified task order
    final unifiedTaskOrder = _parseIntList(json['unifiedTaskOrder']);

    return PursuitFocusState(
      slots: slots,
      projectQueue: projectQueue,
      taskQueues: taskQueues,
      unifiedTaskOrder: unifiedTaskOrder,
    );
  }

  static List<int> _parseIntList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<num>().map((v) => v.toInt()).toList();
  }

  Map<String, dynamic> toJson() => {
        'slots': slots,
        'projectQueue': projectQueue,
        'taskQueues': taskQueues.map((k, v) => MapEntry(k.toString(), v)),
        'unifiedTaskOrder': unifiedTaskOrder,
      };

  String toJsonString() => jsonEncode(toJson());

  static PursuitFocusState? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return PursuitFocusState.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
