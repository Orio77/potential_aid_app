import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/daos/database_projects.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';

class ProjectsNotifier extends StateNotifier<List<ProjectData>> {
  final AppDatabase _database;

  ProjectsNotifier(this._database) : super([]) {
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await _database.getAllProjects();
    state = projects;
  }

  Future<int> addProject(
    String name,
    DateTime startDate,
    DateTime deadline,
    int? startPoint,
    int? current,
    int? goal,
    String? unit,
  ) async {
    final projectId = await _database.addProject(
      name,
      startDate,
      deadline,
      startPoint,
      current,
      goal,
      unit,
    );

    await _loadProjects();

    return projectId;
  }

  Future<ProjectData?> getProjectData(String name) async {
    return await _database.projectDao.getByName(name);
  }
}

final projectsNotifierProvider =
    StateNotifierProvider<ProjectsNotifier, List<ProjectData>>((ref) {
      final database = ref.watch(databaseProvider);
      return ProjectsNotifier(database);
    });
