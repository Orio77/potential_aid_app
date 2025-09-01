import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/tables/project.dart';
import 'package:potential_aid_app/data/tables/block.dart';

part 'project_dao.g.dart';

@DriftAccessor(tables: [Project, Block])
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

  Future<ProjectData?> getByBlockId(int blockId) async {
    return await transaction(() async {
      final blockData = await (select(
        block,
      )..where((b) => b.id.equals(blockId))).getSingleOrNull();
      if (blockData == null) return null;
      final projectData = (select(
        project,
      )..where((p) => p.id.equals(blockData.projectId))).getSingleOrNull();

      return projectData;
    });
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
