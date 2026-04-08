import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/projects/providers/project_categories_notifier.dart';
import 'package:potential_aid_app/projects/widgets/search_bar.dart';

enum BatchCategoryProjectsAction { assign, unassign }

/// Searchable multi-select of root projects to assign to a category or unassign from one.
class BatchCategoryProjectsScreen extends ConsumerStatefulWidget {
  final BatchCategoryProjectsAction action;
  final int categoryId;
  final String categoryTitle;

  const BatchCategoryProjectsScreen({
    super.key,
    required this.action,
    required this.categoryId,
    required this.categoryTitle,
  });

  @override
  ConsumerState<BatchCategoryProjectsScreen> createState() =>
      _BatchCategoryProjectsScreenState();
}

class _BatchCategoryProjectsScreenState
    extends ConsumerState<BatchCategoryProjectsScreen> {
  String _searchQuery = '';
  final GlobalKey<SearchAppBarState> _searchBarKey =
      GlobalKey<SearchAppBarState>();
  final Set<int> _selectedIds = {};
  List<ProjectData> _allRootProjects = [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    Future.microtask(_loadProjects);
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

  Future<void> _loadProjects() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final db = ref.read(databaseProvider);
      final list = await db.projectDao.getAllProjects(null);
      if (!mounted) return;
      setState(() {
        _allRootProjects =
            list.where((p) => p.parentProjectId == null).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  List<ProjectData> get _baseList {
    if (widget.action == BatchCategoryProjectsAction.unassign) {
      return _allRootProjects
          .where((p) => p.category == widget.categoryId)
          .toList();
    }
    return _allRootProjects;
  }

  List<ProjectData> get _visibleProjects {
    final q = _searchQuery.trim().toLowerCase();
    final base = _baseList;
    if (q.isEmpty) return base;
    return base
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();
  }

  String _categoryNameForProject(
    int? categoryId,
    List<ProjectCategoryData> categories,
  ) {
    if (categoryId == null) return 'Uncategorized';
    for (final c in categories) {
      if (c.id == categoryId) {
        return (c.title?.trim().isNotEmpty ?? false) ? c.title! : 'Untitled';
      }
    }
    return 'Unknown category';
  }

  Future<void> _apply() async {
    if (_selectedIds.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final count = _selectedIds.length;
    try {
      await ref.read(projectCategoriesProvider.notifier).batchSetProjectsCategory(
            _selectedIds.toList(),
            widget.action == BatchCategoryProjectsAction.assign
                ? widget.categoryId
                : null,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      final msg = widget.action == BatchCategoryProjectsAction.assign
          ? 'Assigned $count project${count == 1 ? '' : 's'} to "$_shortTitle"'
          : 'Removed $count project${count == 1 ? '' : 's'} from "$_shortTitle"';
      messenger.showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not update: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String get _shortTitle =>
      widget.categoryTitle.length > 24
          ? '${widget.categoryTitle.substring(0, 24)}…'
          : widget.categoryTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(projectCategoriesProvider);
    final categoryMap = {for (final c in categories) c.id: c};

    final title = widget.action == BatchCategoryProjectsAction.assign
        ? 'Assign to $_shortTitle'
        : 'Remove from $_shortTitle';

    return Scaffold(
      appBar: SearchAppBar(
        key: _searchBarKey,
        normalTitle: title,
        titleStyle: theme.textTheme.titleLarge,
        searchHint: 'Search projects…',
        onSearchChanged: (q) {
          setState(() {
            _searchQuery = q.toLowerCase();
          });
        },
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        additionalActions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              setState(() {
                if (value == 'all') {
                  _selectedIds.addAll(_visibleProjects.map((p) => p.id));
                } else if (value == 'clear') {
                  _selectedIds.clear();
                }
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'all', child: Text('Select all visible')),
              PopupMenuItem(value: 'clear', child: Text('Clear selection')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                widget.action == BatchCategoryProjectsAction.assign
                    ? 'Selected projects are moved into this category (replacing their current category).'
                    : 'Choose projects to remove from this category. They become uncategorized.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: $_loadError'),
                  ),
                ),
              )
            else ...[
              if (_baseList.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        widget.action == BatchCategoryProjectsAction.unassign
                            ? 'No projects in this category.'
                            : 'No projects to show.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _visibleProjects.length,
                    itemBuilder: (context, index) {
                      final project = _visibleProjects[index];
                      final currentCatId = project.category;
                      final currentLabel = _categoryNameForProject(
                        currentCatId,
                        categories,
                      );
                      final alreadyInTarget =
                          widget.action == BatchCategoryProjectsAction.assign &&
                          currentCatId == widget.categoryId;
                      final selected = _selectedIds.contains(project.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: CheckboxListTile(
                          value: selected,
                          onChanged: alreadyInTarget
                              ? null
                              : (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selectedIds.add(project.id);
                                    } else {
                                      _selectedIds.remove(project.id);
                                    }
                                  });
                                },
                          title: Text(
                            project.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Icon(
                                    Icons.folder_outlined,
                                    size: 16,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  Text(
                                    'Category: $currentLabel',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (alreadyInTarget)
                                    Chip(
                                      visualDensity: VisualDensity.compact,
                                      label: const Text('Already here'),
                                      labelStyle: theme.textTheme.labelSmall,
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                ],
                              ),
                            ],
                          ),
                          secondary: currentCatId != null &&
                                  categoryMap.containsKey(currentCatId)
                              ? Icon(
                                  Icons.label_outline,
                                  color: theme.colorScheme.primary,
                                )
                              : Icon(
                                  Icons.label_off_outlined,
                                  color: theme.colorScheme.outline,
                                ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _loading || _loadError != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: FilledButton.icon(
                  onPressed: _selectedIds.isEmpty ? null : _apply,
                  icon: Icon(
                    widget.action == BatchCategoryProjectsAction.assign
                        ? Icons.drive_file_move_rtl
                        : Icons.folder_off_outlined,
                  ),
                  label: Text(
                    widget.action == BatchCategoryProjectsAction.assign
                        ? 'Assign ${_selectedIds.length} project${_selectedIds.length == 1 ? '' : 's'}'
                        : 'Uncategorize ${_selectedIds.length} project${_selectedIds.length == 1 ? '' : 's'}',
                  ),
                ),
              ),
            ),
    );
  }
}
