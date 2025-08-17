import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';

class TaskSearchNotifier extends StateNotifier<List<TaskData>> {
  TaskSearchNotifier(this._database) : super([]);

  final AppDatabase _database;

  Future<void> search(
    String query, [
    List<bool Function(TaskData)>? predicates,
    bool andMode = true,
    int limit = 20,
  ]) async {
    final q = query.trim();
    if (q.isEmpty) {
      state = [];
      return;
    }

    final base = await _database.taskDao.searchTasks(query: q, limit: limit);

    if (predicates == null || predicates.isEmpty) {
      state = base;
      return;
    }

    final filtered = base.where((task) {
      return andMode
          ? predicates.every((p) => p(task))
          : predicates.any((p) => p(task));
    }).toList();

    state = filtered;
  }
}

final taskSearchProvider =
    StateNotifierProvider.autoDispose<TaskSearchNotifier, List<TaskData>>((
      ref,
    ) {
      final database = ref.watch(databaseProvider);
      return TaskSearchNotifier(database);
    });
