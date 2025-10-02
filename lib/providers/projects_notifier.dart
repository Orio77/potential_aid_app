import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/daos/database_projects.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/models/project_interval.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:time_machine/time_machine.dart';

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

  Future<int> addProject({
    required String name,
    required DateTime startDate,
    required DateTime deadline,
    int? startPoint,
    int? current,
    int? goal,
    String? unit,
    int? category,
  }) async {
    final projectId = await _database.addProject(
      name: name,
      startDate: startDate,
      deadline: deadline,
      startPoint: startPoint,
      current: current,
      goal: goal,
      unit: unit,
      category: category,
    );

    await _loadProjects();

    return projectId;
  }

  Future<void> deleteProject(int projectId) async {
    await (_database.projectDao.deleteProject(projectId));
  }

  Future<int> updateProject(int projectId, ProjectCompanion updates) async {
    return await _database.projectDao.updateProject(projectId, updates);
  }

  Future<ProjectData?> getProjectData(String name) async {
    return await _database.projectDao.getProjectByName(name);
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
  return await database.projectDao.getProjectById(projectId);
});

final projectByBlockProvider = FutureProvider.family<ProjectData?, int>((
  ref,
  blockId,
) async {
  final database = ref.watch(databaseProvider);
  return await database.projectDao.getProjectByBlockId(blockId);
});

final descendantProjectProvider = FutureProvider.family<List<ProjectData>, int>(
  (ref, projectId) async {
    final database = ref.watch(databaseProvider);
    return await database.projectDao.getAllDescendants(projectId);
  },
);

final projectTimeLineProvider =
    FutureProvider.family<List<ProjectInterval>, LocalDate>((
      ref,
      monthDate,
    ) async {
      final database = ref.watch(databaseProvider);

      final monthStart = LocalDate(
        monthDate.yearOfEra,
        monthDate.monthOfYear,
        monthDate.dayOfMonth,
      );
      final monthEnd = monthStart.addMonths(1).subtractDays(1);

      final projects = await database.projectDao.getProjectsInDateRange(
        monthStart.toDateTimeUnspecified(),
        monthEnd.toDateTimeUnspecified(),
      );

      return projects
          .map(
            (project) => ProjectInterval(
              projectId: project.id,
              name: project.name,
              startDay: LocalDate.dateTime(project.startDate),
              endDay: LocalDate.dateTime(project.deadline),
              color: Colors.lime,
              progress: (project.current / project.goal).toDouble(),
            ),
          )
          .toList();
    });
