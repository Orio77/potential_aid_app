import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/projects/providers/category_project_count_provider.dart';
import 'package:potential_aid_app/projects/providers/project_categories_notifier.dart';
import 'package:potential_aid_app/projects/screens/batch_category_projects_screen.dart';
import 'package:potential_aid_app/projects/widgets/add_project_dialog.dart';
import 'package:potential_aid_app/projects/widgets/categories/category_picker_dialog.dart';
import 'package:potential_aid_app/projects/widgets/project_list.dart';
import 'package:potential_aid_app/projects/widgets/search_bar.dart';

class ProjectListScreen extends ConsumerStatefulWidget {
  final int? categoryId;

  const ProjectListScreen({super.key, this.categoryId});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  String _searchQuery = '';
  final GlobalKey<SearchAppBarState> _searchBarKey =
      GlobalKey<SearchAppBarState>();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!mounted) return false;
    if (ModalRoute.of(context)?.isCurrent != true) return false;
    if (event is KeyDownEvent &&
        HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyF) {
      _searchBarKey.currentState?.activateSearch();
      return true;
    }
    return false;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  String _categoryTitleForId(int id, List<ProjectCategoryData> categories) {
    for (final c in categories) {
      if (c.id == id) {
        return categoryDisplayTitle(c);
      }
    }
    return 'Category';
  }

  Future<void> _pushBatchScreen({
    required BatchCategoryProjectsAction action,
    required int categoryId,
    required String categoryTitle,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => BatchCategoryProjectsScreen(
          action: action,
          categoryId: categoryId,
          categoryTitle: categoryTitle,
        ),
      ),
    );
  }

  Future<void> _pickCategoryThenBatch(BatchCategoryProjectsAction action) async {
    final categories = ref.read(projectCategoriesProvider);
    if (categories.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a category first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final title = action == BatchCategoryProjectsAction.assign
        ? 'Assign projects to…'
        : 'Remove projects from…';
    final picked = await showProjectCategoryPicker(
      context: context,
      categories: categories,
      title: title,
    );
    if (!mounted || picked == null) return;
    await _pushBatchScreen(
      action: action,
      categoryId: picked.id,
      categoryTitle: categoryDisplayTitle(picked),
    );
  }

  List<Widget> _batchMenuActions(BuildContext context) {
    final categories = ref.watch(projectCategoriesProvider);
    final id = widget.categoryId;

    if (id != null) {
      final name = _categoryTitleForId(id, categories);
      return [
        PopupMenuButton<String>(
          tooltip: 'Category batch actions',
          onSelected: (value) async {
            if (value == 'assign') {
              await _pushBatchScreen(
                action: BatchCategoryProjectsAction.assign,
                categoryId: id,
                categoryTitle: name,
              );
            } else if (value == 'unassign') {
              await _pushBatchScreen(
                action: BatchCategoryProjectsAction.unassign,
                categoryId: id,
                categoryTitle: name,
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'assign',
              child: ListTile(
                leading: Icon(Icons.drive_file_move_rtl),
                title: Text('Add projects to this category…'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'unassign',
              child: ListTile(
                leading: Icon(Icons.folder_off_outlined),
                title: Text('Remove projects from this category…'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ];
    }

    return [
      PopupMenuButton<String>(
        tooltip: 'Category batch actions',
        onSelected: (value) {
          if (value == 'assign') {
            _pickCategoryThenBatch(BatchCategoryProjectsAction.assign);
          } else if (value == 'unassign') {
            _pickCategoryThenBatch(BatchCategoryProjectsAction.unassign);
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem<String>(
            value: 'assign',
            child: ListTile(
              leading: Icon(Icons.drive_file_move_rtl),
              title: Text('Assign projects to category…'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem<String>(
            value: 'unassign',
            child: ListTile(
              leading: Icon(Icons.folder_off_outlined),
              title: Text('Remove projects from category…'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildCategoryProjectCountBanner(int categoryId, ThemeData theme) {
    final asyncCount = ref.watch(categoryRootProjectCountProvider(categoryId));

    return asyncCount.when(
      data: (n) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
        child: Row(
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              n == 0
                  ? 'No root-level projects in this category'
                  : '$n root-level project${n == 1 ? '' : 's'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(projectCategoriesProvider);
    final scopedTitle = widget.categoryId != null
        ? _categoryTitleForId(widget.categoryId!, categories)
        : null;

    return Scaffold(
      appBar: SearchAppBar(
        key: _searchBarKey,
        normalTitle: scopedTitle != null ? '$scopedTitle · Projects' : 'Projects',
        searchHint: 'Search projects...',
        onSearchChanged: _onSearchChanged,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        additionalActions: _batchMenuActions(context),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.categoryId != null)
                _buildCategoryProjectCountBanner(widget.categoryId!, theme),
              Expanded(
                child: ProjectList(
                  searchQuery: _searchQuery,
                  category: widget.categoryId,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showAddProjectDialog(context: context, categoryId: widget.categoryId);
        },
        icon: const Icon(Icons.add),
        label: const Text('Project'),
      ),
    );
  }
}
