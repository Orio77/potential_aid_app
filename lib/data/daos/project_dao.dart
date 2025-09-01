import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/tables/project.dart';

part 'project_dao.g.dart';

@DriftAccessor(tables: [Project])
class ProjectDao extends DatabaseAccessor<AppDatabase> with _$ProjectDaoMixin {
  ProjectDao(super.attachedDatabase);

  Future<ProjectData?> getByName(String name) async {
    final query = select(project)..where((p) => p.name.equals(name));

    return await query.getSingleOrNull();
  }

  Future<ProjectData?> getById(int projectId) async {
    final query = select(project)..where((p) => p.id.equals(projectId));

    return await query.getSingleOrNull();
  }

  Future<List<ProjectData>> searchProjects({
    required String query,
    int? limit,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final selectQuery = select(project)
      ..where((p) => p.name.lower().like('${q.toLowerCase()}%'));

    if (limit != null) {
      selectQuery.limit(limit);
    }

    return selectQuery.get();
  }
}
