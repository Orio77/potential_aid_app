import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';

class TaskSearchNotifier extends StateNotifier<List<TaskData>> {
  TaskSearchNotifier(this._database) : super([]);
  static const int maxResults = 3;

  final AppDatabase _database;

  Future<void> search(String query) async {
    List<TaskData> tasks = await _database.getAllTasks();

    var filtered = tasks
        .where((task) => task.name.contains(query))
        .take(maxResults)
        .toList();

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
