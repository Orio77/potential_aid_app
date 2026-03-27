import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/projects/providers/project_categories_notifier.dart';
import 'package:potential_aid_app/projects/widgets/categories/add_to_category_dialog.dart';

class AddToCategory extends ConsumerWidget {
  final int projectId;
  final int? categoryId;
  const AddToCategory({super.key, required this.projectId, this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(
      projectCategoryByProjectIdProvider(projectId),
    );

    return categoryAsync.when(
      data: (category) {
        if (category == null) {
          return IconButton(
            onPressed: () => showAddToCategoryDialog(
              context,
              projectId,
              Icons.category_rounded.codePoint,
            ),
            icon: Icon(Icons.category_rounded),
          );
        } else {
          return IconButton(
            onPressed: () => showAddToCategoryDialog(
              context,
              projectId,
              category.iconCodePoint ?? Icons.category_rounded.codePoint,
            ),
            icon: Icon(
              IconData(
                category.iconCodePoint ?? Icons.category_rounded.codePoint,
                fontFamily: 'MaterialIcons',
              ),
            ),
          );
        }
      },
      loading: () => IconButton(
        onPressed: () => showAddToCategoryDialog(
          context,
          projectId,
          Icons.category_rounded.codePoint,
        ),
        icon: Icon(Icons.category_rounded),
      ),
      error: (error, stackTrace) => IconButton(
        onPressed: () =>
            showAddToCategoryDialog(context, projectId, Icons.error.codePoint),
        icon: Icon(Icons.error),
      ),
    );
  }
}
