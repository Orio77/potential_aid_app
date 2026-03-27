import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/projects/providers/project_categories_notifier.dart';
import 'package:potential_aid_app/projects/screens/project_list_screen.dart';
import 'package:potential_aid_app/widgets/common/reorderable_grid.dart';
import 'package:potential_aid_app/projects/widgets/categories/category_card.dart';

class CategoryList extends ConsumerStatefulWidget {
  final String searchQuery;

  const CategoryList({super.key, this.searchQuery = ''});

  @override
  ConsumerState<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends ConsumerState<CategoryList> {
  bool _isEditMode = false;

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  Future<void> _showDeleteConfirmation(ProjectCategoryData category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${category.title}"?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Projects in this category will be moved to "Uncategorized"',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(projectCategoriesProvider.notifier)
          .deleteProjectCategoryById(category.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "${category.title}" deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildEmptyListView() {
    return Center(child: Text("Create Your First Category to Begin!"));
  }

  Widget _buildCategoryListView(List<ProjectCategoryData> data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return ReorderableListView.builder(
            buildDefaultDragHandles: !_isEditMode,
            onReorder: (oldIndex, newIndex) async {
              if (!_isEditMode) {
                await ref
                    .read(projectCategoriesProvider.notifier)
                    .reorderCategories(oldIndex, newIndex);
              }
            },
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final category = data[index];
              return Padding(
                key: Key(category.id.toString()),
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Stack(
                  children: [
                    InkWell(
                      onTap: _isEditMode
                          ? null
                          : () => _pushProjectListScreen(context, category.id),
                      child: CategoryCard(data: category),
                    ),
                    if (_isEditMode)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.remove, color: Colors.white),
                            iconSize: 18,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                            onPressed: () => _showDeleteConfirmation(category),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        }

        int crossAxisCount;
        double childAspectRatio;

        if (constraints.maxWidth < 900) {
          crossAxisCount = 2;
          childAspectRatio = 0.9;
        } else {
          crossAxisCount = 3;
          childAspectRatio = 0.9;
        }

        return ReorderableGrid<ProjectCategoryData>(
          data: data,
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          constraints: constraints,
          onReorder: (oldIndex, newIndex) async {
            if (!_isEditMode) {
              await ref
                  .read(projectCategoriesProvider.notifier)
                  .reorderCategories(oldIndex, newIndex);
            }
          },
          onTap: _isEditMode
              ? (context, category) {}
              : (context, category) =>
                    _pushProjectListScreen(context, category.id),
          itemBuilder: (category) => _buildCategoryCardWithDelete(category),
        );
      },
    );
  }

  Widget _buildCategoryCardWithDelete(ProjectCategoryData category) {
    if (_isEditMode) {
      return Stack(
        children: [
          CategoryCard(data: category),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.remove, color: Colors.white),
                iconSize: 18,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                onPressed: () => _showDeleteConfirmation(category),
              ),
            ),
          ),
        ],
      );
    } else {
      return CategoryCard(data: category);
    }
  }

  void _pushProjectListScreen(BuildContext context, int? categoryId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectListScreen(categoryId: categoryId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allData = ref.watch(projectCategoriesProvider);
    final data = widget.searchQuery.isEmpty
        ? allData
        : allData
            .where(
              (c) => (c.title ?? '')
                  .toLowerCase()
                  .contains(widget.searchQuery.toLowerCase()),
            )
            .toList();

    if (data.isEmpty) {
      return _buildEmptyListView();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEditMode ? 'Select categories to delete' : 'Categories',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _isEditMode
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
              ),
              TextButton.icon(
                onPressed: _toggleEditMode,
                icon: Icon(_isEditMode ? Icons.done : Icons.edit),
                label: Text(_isEditMode ? 'Done' : 'Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: _isEditMode
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildCategoryListView(data)),
      ],
    );
  }
}
