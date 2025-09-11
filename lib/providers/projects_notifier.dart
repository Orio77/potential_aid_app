import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/daos/database_projects.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';

class ProjectsNotifier extends StateNotifier<List<ProjectData>> {
  List<Expression<bool> Function($ProjectTable)>? predicates;
  final AppDatabase _database;

  ProjectsNotifier(this._database) : super([]) {
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await _database.getAllProjects(predicates);
    state = projects;
  }

  void setPredicates(
    List<Expression<bool> Function($ProjectTable)>? newPredicates,
  ) {
    predicates = newPredicates;
    _loadProjects();
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

  Future<void> moveProject(int projectId, int newParentId) async {
    if (await _wouldCreateCircle(projectId, newParentId)) {
      throw Exception('Cannot move project: would create circular reference');
    }

    await _database.projectDao.updateProject(
      projectId,
      ProjectCompanion(parentProjectId: Value(newParentId)),
    );
    await _loadProjects();
  }

  Future<bool> _wouldCreateCircle(int projectId, int potentialParentId) async {
    final ancestors = await _database.projectDao.getProjectHierarchy(
      potentialParentId,
    );
    return ancestors.any((p) => p.id == projectId);
  }
}

final projectsNotifierProvider =
    StateNotifierProvider<ProjectsNotifier, List<ProjectData>>((ref) {
      final database = ref.watch(databaseProvider);
      return ProjectsNotifier(database);
    });

final projectProvider = FutureProvider.family<ProjectData?, int>((
  ref,
  projectId,
) async {
  final database = ref.watch(databaseProvider);
  return await database.projectDao.getById(projectId);
});

final projectByBlockProvider = FutureProvider.family<ProjectData?, int>((
  ref,
  blockId,
) async {
  final database = ref.watch(databaseProvider);
  return await database.projectDao.getByBlockId(blockId);
});

final descendantProjectProvider = FutureProvider.family<List<ProjectData>, int>(
  (ref, projectId) async {
    final database = ref.watch(databaseProvider);
    return await database.projectDao.getAllDescendants(projectId);
  },
);
