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

  Future<void> deleteProject(int projectId) async {
    await (delete(project)..where((p) => p.id.equals(projectId))).go();
  }

  Future<int> updateProject(int projectId, ProjectCompanion updates) async {
    return await (update(
      project,
    )..where((p) => p.id.equals(projectId))).write(updates);
  }

  Future<List<ProjectData>> searchProjects({
    required String query,
    int? limit,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final selectQuery = select(project)
      ..where((p) => p.name.lower().contains('${q.toLowerCase()}%'));

    if (limit != null) {
      selectQuery.limit(limit);
    }

    return selectQuery.get();
  }

  Future<int> addProjectCompletion(int projectId, int completionCount) async {
    final projectData = await (select(
      project,
    )..where((p) => p.id.equals(projectId))).getSingle();

    final projectCompanion = ProjectCompanion(
      current: Value(projectData.current + completionCount),
    );

    final res = await (update(
      project,
    )..where((p) => p.id.equals(projectId))).write(projectCompanion);

    return res;
  }

  Future<List<ProjectData>> getChildProjects(int parentId) async {
    return await (select(
      project,
    )..where((p) => p.parentProjectId.equals(parentId))).get();
  }

  Future<ProjectData?> getParentProject(int projectId) async {
    return await (select(
      project,
    )..where((p) => p.parentProjectId.equals(projectId))).getSingleOrNull();
  }

  Future<List<ProjectData>> getAllDescendants(int projectId) async {
    final descendants = <ProjectData>[];
    final children = await getChildProjects(projectId);

    for (final child in children) {
      descendants.add(child);
      descendants.addAll(await getAllDescendants(child.id));
    }

    return descendants;
  }

  Future<List<ProjectData>> getProjectHierarchy(int projectId) async {
    final hierarchy = <ProjectData>[];
    ProjectData? current = await getById(projectId);

    while (current != null) {
      hierarchy.insert(0, current);
      if (current.parentProjectId == null) break;
      current = await getById(current.parentProjectId!);
    }

    return hierarchy;
  }
}
