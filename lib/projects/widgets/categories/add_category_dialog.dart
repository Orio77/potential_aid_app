import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/projects/providers/project_categories_notifier.dart';

class AddCategoryDialog extends ConsumerStatefulWidget {
  const AddCategoryDialog({super.key});

  @override
  ConsumerState<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends ConsumerState<AddCategoryDialog> {
  late TextEditingController _categoryNameController;
  IconData? _chosenIcon;

  @override
  void initState() {
    super.initState();
    _categoryNameController = TextEditingController();
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navi = Navigator.of(context);

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _categoryNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Category name (optional)...",
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _chosenIcon != null ? Colors.blue : Colors.grey,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () => _pickIcon(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _chosenIcon ?? Icons.category_outlined,
                          size: 24,
                          color: _chosenIcon != null ? null : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _chosenIcon != null
                              ? 'Icon selected'
                              : 'Tap to select icon',
                          style: TextStyle(
                            color: _chosenIcon != null ? null : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (_chosenIcon != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _chosenIcon = null;
                          });
                        },
                        tooltip: 'Remove icon',
                      ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await _saveCategory(
                    _chosenIcon?.codePoint,
                    _categoryNameController.text.trim(),
                  );
                  navi.pop();
                },
                child: Text('save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickIcon(BuildContext context) async {
    final icon = await showIconPicker(
      context,
      configuration: SinglePickerConfiguration(
        showTooltips: true,
        iconPackModes: [IconPack.allMaterial],
      ),
    );
    if (icon != null) {
      setState(() {
        _chosenIcon = icon.data;
      });
    }
  }

  Future<void> _saveCategory(int? iconCode, String? title) async {
    await ref
        .read(projectCategoriesProvider.notifier)
        .addCategory(iconCode: iconCode, title: title);
  }
}

Future<void> showAddCategoryDialog(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (context) => const AddCategoryDialog(),
  );
}
