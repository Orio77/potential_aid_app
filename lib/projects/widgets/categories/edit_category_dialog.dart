import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/projects/providers/project_categories_notifier.dart';
import 'package:potential_aid_app/projects/widgets/categories/category_icon_picker_sheet.dart';

class EditCategoryDialog extends ConsumerStatefulWidget {
  final ProjectCategoryData category;

  const EditCategoryDialog({super.key, required this.category});

  @override
  ConsumerState<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends ConsumerState<EditCategoryDialog> {
  late final TextEditingController _nameController;
  IconData? _chosenIcon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.title ?? '');
    final code = widget.category.iconCodePoint;
    _chosenIcon = code != null
        ? IconData(code, fontFamily: 'MaterialIcons')
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final icon = await showCategoryIconPicker(context);
    if (icon != null && mounted) {
      setState(() => _chosenIcon = icon);
    }
  }

  Future<void> _save() async {
    final raw = _nameController.text.trim();
    final title = raw.isEmpty ? null : raw;
    await ref.read(projectCategoriesProvider.notifier).updateProjectCategory(
          widget.category.id,
          ProjectCategoryCompanion(
            title: Value(title),
            iconCodePoint: Value(_chosenIcon?.codePoint),
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Edit category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Name',
                hintText: 'Optional',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Text(
              'Icon',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Material(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: _pickIcon,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _chosenIcon ?? Icons.category_outlined,
                        size: 28,
                        color: _chosenIcon != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _chosenIcon != null
                              ? 'Tap to change icon'
                              : 'Tap to choose an icon',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      if (_chosenIcon != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Remove icon',
                          onPressed: () => setState(() => _chosenIcon = null),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

Future<void> showEditCategoryDialog(
  BuildContext context,
  ProjectCategoryData category,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => EditCategoryDialog(category: category),
  );
}
