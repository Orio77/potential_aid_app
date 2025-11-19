import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/tables/project.dart';
import 'package:potential_aid_app/data/tables/block.dart';
import 'package:potential_aid_app/data/tables/project_category.dart';

part 'project_dao.g.dart';

@DriftAccessor(tables: [Project, ProjectCategory, Block])
class ProjectDao extends DatabaseAccessor<AppDatabase> with _$ProjectDaoMixin {
  ProjectDao(super.attachedDatabase);

  // Sync helper methods
  ProjectCompanion _withSyncFieldsP(ProjectCompanion companion) {
    return companion.copyWith(
      lastModified: Value(DateTime.now()),
      needsSync: Value(true),
      version: Value(
        (companion.version.present ? companion.version.value : 1) + 1,
      ),
    );
  }

  ProjectCategoryCompanion _withSyncFieldsPC(
    ProjectCategoryCompanion companion,
  ) {
    return companion.copyWith(
      lastModified: Value(DateTime.now()),
      needsSync: Value(true),
      version: Value(
        (companion.version.present ? companion.version.value : 1) + 1,
      ),
    );
  }

  ProjectCompanion _markProjectForDeletion(int version) {
    return ProjectCompanion(
      isDeleted: Value(true),
      needsSync: Value(true),
      lastModified: Value(DateTime.now()),
      version: Value(version + 1),
    );
  }

  ProjectCategoryCompanion _markCategoryForDeletion(int version) {
    return ProjectCategoryCompanion(
      isDeleted: Value(true),
      needsSync: Value(true),
      lastModified: Value(DateTime.now()),
      version: Value(version + 1),
    );
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
    final projectComp = ProjectCompanion(
      name: Value(name),
      startDate: Value(startDate),
      startPoint: Value(startPoint ?? 0),
      deadline: Value(deadline),
      current: Value(current ?? 0),
      goal: Value(goal ?? 1),
      unit: Value(unit ?? ""),
      category: Value(category),
      lastModified: Value(DateTime.now()),
    );

    final syncedProjectComp = _withSyncFieldsP(projectComp);

    return await into(project).insert(syncedProjectComp);
  }

  Future<ProjectData?> getProjectByName(String name) async {
    final query = select(project)..where((p) => p.name.equals(name));

    return await query.getSingleOrNull();
  }

  Future<ProjectData?> getProjectById(int projectId) async {
    final query = select(project)..where((p) => p.id.equals(projectId));

    return await query.getSingleOrNull();
  }

  Future<ProjectData?> getProjectByBlockId(int blockId) async {
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

  Future<List<ProjectData>> getAllProjects([
    List<Expression<bool> Function($ProjectTable)>? predicates,
  ]) {
    final query = select(project);
    query.where((p) => p.isDeleted.equals(false));

    if (predicates != null && predicates.isNotEmpty) {
      for (final pred in predicates) {
        query.where(pred);
      }
    }

    return query.get();
  }

  Future<List<ProjectData>> getProjectsInDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return await (select(project)..where(
          (p) =>
              p.startDate.isSmallerOrEqualValue(end) &
              p.deadline.isBiggerOrEqualValue(start),
        ))
        .get();
  }

  Future<List<ProjectData>> getProjectsWithDeadlineInRange(
    DateTime start,
    DateTime end,
  ) async {
    return await (select(project)..where(
          (p) =>
              p.deadline.isSmallerOrEqualValue(end) &
              p.deadline.isBiggerOrEqualValue(start),
        ))
        .get();
  }

  Future<List<ProjectData>> getProjectsInProgress(DateTime curDate) async {
    return await (select(
      project,
    )..where((p) => p.deadline.isBiggerOrEqualValue(curDate))).get();
  }

  Future<List<ProjectData>> getProjectsInProgressInDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final selected =
        await (select(project)..where(
              (p) =>
                  p.deadline.isBiggerOrEqualValue(start) &
                  p.startDate.isSmallerOrEqualValue(end),
            ))
            .get();

    return selected;
  }

  Future<void> deleteProject(int projectId) async {
    // Get current version for soft delete
    final currentProject = await getProjectById(projectId);
    if (currentProject != null) {
      final deleteCompanion = _markProjectForDeletion(currentProject.version);
      await (update(
        project,
      )..where((p) => p.id.equals(projectId))).write(deleteCompanion);
    }
  }

  Future<int> updateProject(int projectId, ProjectCompanion updates) async {
    final syncAwareUpdates = _withSyncFieldsP(updates);
    return await (update(
      project,
    )..where((p) => p.id.equals(projectId))).write(syncAwareUpdates);
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

    final projectCompanion = _withSyncFieldsP(
      ProjectCompanion(current: Value(projectData.current + completionCount)),
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
    ProjectData? current = await getProjectById(projectId);

    while (current != null) {
      hierarchy.insert(0, current);
      if (current.parentProjectId == null) break;
      current = await getProjectById(current.parentProjectId!);
    }

    return hierarchy;
  }

  Future<int> addCategory({
    String? title,
    int? iconCode,
    int? orderIndex,
  }) async {
    var companion = _withSyncFieldsPC(
      ProjectCategoryCompanion.insert(
        title: Value(title),
        iconCodePoint: Value(iconCode),
        orderIndex: Value(orderIndex),
        lastModified: DateTime.now(),
      ),
    );
    return await into(projectCategory).insert(companion);
  }

  Future<ProjectCategoryData> getProjectCategoryById(
    int projectCategoryId,
  ) async {
    return await (select(
      projectCategory,
    )..where((pc) => pc.id.equals(projectCategoryId))).getSingle();
  }

  Future<ProjectCategoryData> getProjectCategoryByProjectId(
    int projectId,
  ) async {
    final projectData = await (select(
      project,
    )..where((p) => p.id.equals(projectId))).getSingle();

    return await (select(
      projectCategory,
    )..where((c) => c.id.equals(projectData.category!))).getSingle();
  }

  Future<List<ProjectCategoryData>> getAllProjectCategories() async {
    return await (select(
      projectCategory,
    )..orderBy([(pc) => OrderingTerm.asc(pc.orderIndex)])).get();
  }

  Future<int> updateProjectCategory(
    int categoryId,
    ProjectCategoryCompanion updates,
  ) async {
    final syncAwareUpdates = _withSyncFieldsPC(updates);
    return await (update(
      projectCategory,
    )..where((pc) => pc.id.equals(categoryId))).write(syncAwareUpdates);
  }

  Future<void> deleteProjectCategoryById(int projectCategoryId) async {
    // Get current version for soft delete
    final currentCategory = await getProjectCategoryById(projectCategoryId);
    final deleteCompanion = _markCategoryForDeletion(currentCategory.version);

    await (update(
      projectCategory,
    )..where((pc) => pc.id.equals(projectCategoryId))).write(deleteCompanion);
  }

  Future<List<ProjectData>> getProjectsByCategory(int categoryId) async {
    return await (select(
      project,
    )..where((p) => p.category.equals(categoryId))).get();
  }
}
