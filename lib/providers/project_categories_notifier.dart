import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';

class ProjectCategoriesNotifier
    extends StateNotifier<List<ProjectCategoryData>> {
  final AppDatabase _database;
  final Ref _ref;

  ProjectCategoriesNotifier(this._database, this._ref) : super([]) {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    state = await _database.projectDao.getAllProjectCategories();
  }

  Future<int> addCategory({
    String? title,
    int? iconCode,
    int? orderIndex,
  }) async {
    final categoryId = await _database.projectDao.addCategory(
      iconCode: iconCode,
      title: title,
      orderIndex: orderIndex,
    );
    await _loadCategories();
    return categoryId;
  }

  Future<ProjectCategoryData> getProjectCategoryById(
    int projectCategoryId,
  ) async {
    return await _database.projectDao.getProjectCategoryById(projectCategoryId);
  }

  Future<ProjectCategoryData> getProjectCategoryByProjectId(
    int projectId,
  ) async {
    return await _database.projectDao.getProjectCategoryByProjectId(projectId);
  }

  Future<List<ProjectCategoryData>> getAllProjectCategories() async {
    return await _database.projectDao.getAllProjectCategories();
  }

  Future<int> updateProjectCategory(ProjectCategoryCompanion updates) async {
    final categoryId = await _database.projectDao.updateProjectCategory(
      updates,
    );
    await _loadCategories();
    return categoryId;
  }

  Future<void> deleteProjectCategoryById(int projectCategoryId) async {
    await _database.projectDao.deleteProjectCategoryById(projectCategoryId);
    await _loadCategories();
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    final currentState = [...state];

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final item = currentState.removeAt(oldIndex);
    currentState.insert(newIndex, item);

    state = currentState;

    await _updateOrderIndicesInDatabase(currentState);
  }

  Future<void> _updateOrderIndicesInDatabase(
    List<ProjectCategoryData> orderedCategories,
  ) async {
    for (int i = 0; i < orderedCategories.length; i++) {
      final category = orderedCategories[i];
      await _database.projectDao.updateProjectCategory(
        ProjectCategoryCompanion(id: Value(category.id), orderIndex: Value(i)),
      );
    }

    await _loadCategories();
  }

  Future<void> updateProjectsCategory(int projectId, int categoryId) async {
    final updates = ProjectCompanion(category: Value(categoryId));
    await _database.projectDao.updateProject(projectId, updates);
  }
}

final projectCategoriesProvider =
    StateNotifierProvider<ProjectCategoriesNotifier, List<ProjectCategoryData>>(
      (ref) {
        final database = ref.watch(databaseProvider);
        return ProjectCategoriesNotifier(database, ref);
      },
    );

final projectCategoryByIdProvider =
    FutureProvider.family<ProjectCategoryData, int>((
      ref,
      projectCategoryId,
    ) async {
      final database = ref.watch(databaseProvider);
      return await database.projectDao.getProjectCategoryById(
        projectCategoryId,
      );
    });

final projectCategoryByProjectIdProvider =
    FutureProvider.family<ProjectCategoryData?, int>((ref, projectId) async {
      final database = ref.watch(databaseProvider);
      try {
        return await database.projectDao.getProjectCategoryByProjectId(
          projectId,
        );
      } catch (e) {
        // Return null if no category is found for this project
        return null;
      }
    });
