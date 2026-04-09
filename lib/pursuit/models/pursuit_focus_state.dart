import 'dart:convert';

/// Persisted pursuit focus: up to 3 active projects, a backlog queue, and
/// per-project ordered task queues (FIFO heads).
class PursuitFocusState {
  static const int slotCount = 3;

  /// Up to three slot indices; each holds a project id or null.
  final List<int?> slots;

  /// Projects waiting to fill a slot when one completes (FIFO).
  final List<int> projectQueue;

  /// For each project id, ordered task ids (next up first).
  final Map<int, List<int>> taskQueues;

  const PursuitFocusState({
    required this.slots,
    required this.projectQueue,
    required this.taskQueues,
  });

  factory PursuitFocusState.initial() => PursuitFocusState(
        slots: List<int?>.filled(slotCount, null),
        projectQueue: [],
        taskQueues: {},
      );

  PursuitFocusState copyWith({
    List<int?>? slots,
    List<int>? projectQueue,
    Map<int, List<int>>? taskQueues,
  }) {
    return PursuitFocusState(
      slots: slots ?? List<int?>.from(this.slots),
      projectQueue: projectQueue ?? List<int>.from(this.projectQueue),
      taskQueues: taskQueues != null
          ? Map<int, List<int>>.fromEntries(
              taskQueues.entries.map(
                (e) => MapEntry(e.key, List<int>.from(e.value)),
              ),
            )
          : Map<int, List<int>>.fromEntries(
              this.taskQueues.entries.map(
                (e) => MapEntry(e.key, List<int>.from(e.value)),
              ),
            ),
    );
  }

  /// Decode JSON; does not validate against the database.
  factory PursuitFocusState.fromJson(Map<String, dynamic> json) {
    final slotList = json['slots'] as List<dynamic>?;
    final slots = List<int?>.filled(slotCount, null);
    if (slotList != null) {
      for (var i = 0; i < slotCount && i < slotList.length; i++) {
        final v = slotList[i];
        if (v is int) {
          slots[i] = v;
        } else if (v is num) {
          slots[i] = v.toInt();
        }
      }
    }

    final pq = json['projectQueue'] as List<dynamic>?;
    final projectQueue = <int>[];
    if (pq != null) {
      for (final v in pq) {
        if (v is int) {
          projectQueue.add(v);
        } else if (v is num) {
          projectQueue.add(v.toInt());
        }
      }
    }

    final tqRaw = json['taskQueues'] as Map<String, dynamic>?;
    final taskQueues = <int, List<int>>{};
    if (tqRaw != null) {
      for (final e in tqRaw.entries) {
        final pid = int.tryParse(e.key);
        if (pid == null) continue;
        final list = e.value as List<dynamic>?;
        if (list == null) continue;
        final ids = <int>[];
        for (final v in list) {
          if (v is int) {
            ids.add(v);
          } else if (v is num) {
            ids.add(v.toInt());
          }
        }
        if (ids.isNotEmpty) {
          taskQueues[pid] = ids;
        }
      }
    }

    return PursuitFocusState(
      slots: slots,
      projectQueue: projectQueue,
      taskQueues: taskQueues,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slots': slots,
      'projectQueue': projectQueue,
      'taskQueues': taskQueues.map((k, v) => MapEntry(k.toString(), v)),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static PursuitFocusState? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return PursuitFocusState.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
