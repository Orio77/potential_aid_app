import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/project_categories_notifier.dart';

class AddToCategoryDialog extends ConsumerStatefulWidget {
  final int projectId;
  final int iconCodePoint;
  const AddToCategoryDialog({
    super.key,
    required this.projectId,
    required this.iconCodePoint,
  });

  @override
  ConsumerState<AddToCategoryDialog> createState() =>
      _AddToCategoryDialogState();
}

class _AddToCategoryDialogState extends ConsumerState<AddToCategoryDialog> {
  ProjectCategoryData? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = ProjectCategoryData(
      id: -1,
      iconCodePoint: widget.iconCodePoint,
      lastModified: DateTime.now(),
      needsSync: true,
      isDeleted: false,
      version: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(projectCategoriesProvider);
    final navigator = Navigator.of(context);

    return AlertDialog(
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Selected Category: "),

                  if (_selectedCategory != null) ...[
                    if (_selectedCategory!.iconCodePoint != null)
                      Icon(
                        IconData(
                          _selectedCategory!.iconCodePoint!,
                          fontFamily: 'MaterialIcons',
                        ),
                      ),
                    if (_selectedCategory!.title != null)
                      Text(_selectedCategory!.title!)
                    else
                      Text("Untitled"),
                  ] else
                    Text("None selected"),
                ],
              ),
              trailing: IconButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                  });
                },
                icon: Icon(Icons.cancel_rounded),
              ),
            ),
            const SizedBox(height: 8),
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
                          ? Icon(
                              IconData(
                                category.iconCodePoint!,
                                fontFamily: 'MaterialIcons',
                              ),
                            )
                          : const Icon(Icons.category),
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    );
                  },
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => navigator.pop(),
                  child: Text("cancel"),
                ),
                TextButton(
                  onPressed:
                      (_selectedCategory != null && _selectedCategory!.id == -1)
                      ? null
                      : () async {
                          await _addProjectToCategory(
                            widget.projectId,
                            _selectedCategory!.id,
                          );
                          navigator.pop();
                        },

                  child: Text("save"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addProjectToCategory(int projectId, int categoryId) async {
    await ref
        .read(projectCategoriesProvider.notifier)
        .updateProjectsCategory(projectId, categoryId);

    ref.invalidate(projectCategoryByProjectIdProvider(projectId));
    ref.invalidate(projectCategoryByIdProvider(categoryId));
  }
}

Future<void> showAddToCategoryDialog(
  BuildContext context,
  int projectId,
  int iconCodePoint,
) async {
  await showDialog(
    context: context,
    builder: (context) =>
        AddToCategoryDialog(projectId: projectId, iconCodePoint: iconCodePoint),
  );
}
