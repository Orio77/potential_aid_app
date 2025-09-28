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
}

final projectCategoriesNotifier =
    StateNotifierProvider<ProjectCategoriesNotifier, List<ProjectCategoryData>>(
      (ref) {
        final database = ref.watch(databaseProvider);
        return ProjectCategoriesNotifier(database, ref);
      },
    );
