import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/projects/providers/project_categories_notifier.dart';

class MyCategoriesPickerDialog extends ConsumerStatefulWidget {
  const MyCategoriesPickerDialog({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MyCategoriesPickerDialogState();
}

class _MyCategoriesPickerDialogState
    extends ConsumerState<MyCategoriesPickerDialog> {
  ProjectCategoryData? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(projectCategoriesProvider);

    return AlertDialog(
      title: Row(
        children: [
          const Text("Selected Category: "),
          if (_selectedCategory == null) const Text("None"),
          if (_selectedCategory != null &&
              _selectedCategory!.iconCodePoint != null)
            Icon(
              IconData(
                _selectedCategory!.iconCodePoint!,
                fontFamily: 'MaterialIcons',
              ),
            ),
          if (_selectedCategory != null && _selectedCategory!.title != null)
            Text(_selectedCategory!.title!),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 350,
        child: ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = _selectedCategory?.id == category.id;
            return ListTile(
              leading: Icon(
                IconData(
                  category.iconCodePoint ?? 0,
                  fontFamily: 'MaterialIcons',
                ),
              ),
              title: Text(category.title ?? ''),
              selected: isSelected,
              onTap: () {
                setState(() {
                  if (_selectedCategory == category) {
                    _selectedCategory = null;
                  } else {
                    _selectedCategory = category;
                  }
                });
              },
            );
          },
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedCategory);
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}

Future<ProjectCategoryData?>? showMyCategoriesPickerDialog(
  BuildContext context,
) async {
  return await showDialog<ProjectCategoryData?>(
    context: context,
    builder: (context) => const MyCategoriesPickerDialog(),
  );
}
