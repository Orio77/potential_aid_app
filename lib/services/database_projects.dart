import 'package:drift/drift.dart';
import 'package:potential_aid_app/services/database.dart';
import 'package:time_machine/time_machine.dart';

extension AppDatabaseProjects on AppDatabase {
  Future<int> addProject(
    String name,
    DateTime deadline,
    DateTime startDate,
  ) async {
    final now = Instant.now().inUtc().toDateTimeUtc();
    final projectComp = ProjectCompanion(
      name: Value(name),
      deadline: Value(deadline),
      startDate: Value(startDate),
      createdAt: Value(now),
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
