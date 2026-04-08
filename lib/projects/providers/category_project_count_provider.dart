import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';

/// Root projects in a category; refreshes when the global projects list changes.
final categoryRootProjectCountProvider =
    FutureProvider.autoDispose.family<int, int>((ref, categoryId) async {
      ref.watch(projectsNotifierProvider);
      final db = ref.read(databaseProvider);
      return db.projectDao.countRootProjectsInCategory(categoryId);
    });
