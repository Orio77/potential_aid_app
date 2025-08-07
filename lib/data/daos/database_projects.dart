import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';

extension AppDatabaseProjects on AppDatabase {
  Future<int> addProject(
    String name,
    DateTime startDate,
    DateTime deadline,
    int? startPoint,
    int? current,
    int? goal,
    String? unit,
  ) async {
    final projectComp = ProjectCompanion(
      name: Value(name),
      startDate: Value(startDate),
      startPoint: Value(startPoint ?? 0),
      deadline: Value(deadline),
      current: Value(current ?? 0),
      goal: Value(goal ?? 1),
      unit: Value(unit ?? ""),
    );

    return await into(project).insert(projectComp);
  }

  Future<int> deleteProject(int projectId) async {
    final query = delete(project)
      ..where((project) => project.id.equals(projectId));

    return await query.go();
  }

  Future<List<ProjectData>> getAllProjects() {
    final query = select(project);

    return query.get();
  }
}
