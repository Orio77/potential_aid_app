import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';

class ProjectSearchNotifier extends StateNotifier<List<ProjectData>> {
  final AppDatabase _database;

  ProjectSearchNotifier(this._database) : super([]);

  Future<void> search(
    String query, [
    List<bool Function(ProjectData)>? predicates,
    bool andMode = true,
    int limit = 20,
  ]) async {
    final q = query.trim();
    if (q.isEmpty) {
      state = [];
      return;
    }

    predicates ??= [];
    predicates.add((ProjectData p) => p.isDeleted == false);

    List<ProjectData> base = await _database.projectDao.searchProjects(
      query: query,
      limit: limit,
    );

    if (predicates.isEmpty) {
      state = base;
      return;
    }

    final filtered = base.where((project) {
      return andMode
          ? predicates!.every((p) => p(project))
          : predicates!.any((p) => p(project));
    }).toList();

    state = filtered;
  }
}

final projectSearchProvider =
    StateNotifierProvider.autoDispose<ProjectSearchNotifier, List<ProjectData>>(
      (ref) {
        final database = ref.watch(databaseProvider);
        return ProjectSearchNotifier(database);
      },
    );
