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
      final results = <bool>[];
      for (int i = 0; i < predicates.length; i++) {
        try {
          final result = predicates[i](task);
          results.add(result);
        } catch (e) {
          results.add(false);
        }
      }

      final finalResult = andMode
          ? results.every((r) => r)
          : results.any((r) => r);

      return finalResult;
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
