import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/project_categories_notifier.dart';

class AddToCategoryDialog extends ConsumerStatefulWidget {
  final int projectId;
  const AddToCategoryDialog({super.key, required this.projectId});

  @override
  ConsumerState<AddToCategoryDialog> createState() => _AddToCategoryDialogState();
}

class _AddToCategoryDialogState extends ConsumerState<AddToCategoryDialog> {
  ProjectCategoryData? category;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(projectCategoriesProvider);

    return AlertDialog(
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (categories.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (BuildContext context, int index) {
                    final category = categories[index];
                    return ListTile(
                      title: Text(category.title ?? 'Untitled Category'),
                      leading: category.iconCodePoint != null
                          ? Icon(IconData(category.iconCodePoint!, fontFamily: 'MaterialIcons'))
                          : const Icon(Icons.category),
                      onTap: () {
                        _addProjectToCategory(widget.projectId, category.id);
                        Navigator.of(context).pop(category);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addProjectToCategory(int projectId, int categoryId) async {
    await ref.read(projectCategoriesProvider.notifier).updateProjectsCategory(projectId, categoryId);
  }
}

Future<void> showAddToCategoryDialog(BuildContext context, int projectId) async {
  await showDialog(
    context: context,
    builder: (context) => AddToCategoryDialog(projectId: projectId,),
  );
}