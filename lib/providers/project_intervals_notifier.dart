import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/models/project_interval.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:drift/drift.dart';
import 'package:time_machine/time_machine.dart';
import 'package:flutter/material.dart';

// Manages projects as a Map for efficient individual updates
class ProjectIntervalsNotifier
    extends StateNotifier<Map<int, ProjectInterval>> {
  final AppDatabase _database;

  ProjectIntervalsNotifier(this._database) : super({});

  // Load projects for a specific month
  Future<void> loadProjectsForMonth(LocalDate monthDate) async {
    final monthStart = LocalDate(
      monthDate.yearOfEra,
      monthDate.monthOfYear,
      monthDate.dayOfMonth,
    );
    // final monthEnd = monthStart.addMonths(1).subtractDays(1);

    final projects = await _database.projectDao.getProjectsInProgress(
      monthStart.toDateTimeUnspecified(),
    );

    final projectIntervals = projects
        .map(
          (project) => ProjectInterval(
            projectId: project.id,
            name: project.name,
            startDay: LocalDate.dateTime(project.startDate),
            endDay: LocalDate.dateTime(project.deadline),
            color: project.color != null ? Color(project.color!) : null,
            categoryId: project.category,
            progress: (project.current / project.goal).toDouble(),
          ),
        )
        .toList();

    setProjects(projectIntervals);
  }

  void setProjects(List<ProjectInterval> projects) {
    state = {
      for (final project in projects)
        if (project.projectId != null) project.projectId!: project,
    };
  }

  void updateProject(int projectId, ProjectInterval updatedProject) {
    state = {...state, projectId: updatedProject};
  }

  Future<void> persistProjectUpdate(ProjectInterval project) async {
    if (project.projectId == null) return;

    // Update in database
    await _database.projectDao.updateProject(
      project.projectId!,
      ProjectCompanion(
        startDate: Value(project.startDay.toDateTimeUnspecified()),
        deadline: Value(project.endDay.toDateTimeUnspecified()),
      ),
    );

    // Update local state for the updated project
    updateProject(project.projectId!, project);

    // Reload all projects to ensure consistency across all cached data
    await reloadAllProjects();
  }

  Future<void> reloadAllProjects() async {
    // Get all projects currently in progress and update the state
    final allProjects = await _database.projectDao.getProjectsInProgress(
      LocalDate.today().toDateTimeUnspecified(),
    );

    final projectIntervals = allProjects
        .map(
          (project) => ProjectInterval(
            projectId: project.id,
            name: project.name,
            startDay: LocalDate.dateTime(project.startDate),
            endDay: LocalDate.dateTime(project.deadline),
            color: project.color != null ? Color(project.color!) : null,
            categoryId: project.category,
            progress: (project.current / project.goal).toDouble(),
          ),
        )
        .toList();

    setProjects(projectIntervals);
  }

  List<ProjectInterval> get projectsList => state.values.toList();
}

final projectIntervalsNotifierProvider =
    StateNotifierProvider<ProjectIntervalsNotifier, Map<int, ProjectInterval>>((
      ref,
    ) {
      final database = ref.watch(databaseProvider);
      return ProjectIntervalsNotifier(database);
    });

// Individual project provider - ONLY rebuilds when THIS specific project changes
final individualProjectProvider = Provider.family<ProjectInterval?, int>((
  ref,
  projectId,
) {
  final projectsMap = ref.watch(projectIntervalsNotifierProvider);
  return projectsMap[projectId];
});
