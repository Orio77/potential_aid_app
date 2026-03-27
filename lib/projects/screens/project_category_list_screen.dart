import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/projects/widgets/add_project_dialog.dart';
import 'package:potential_aid_app/projects/widgets/categories/add_category_dialog.dart';
import 'package:potential_aid_app/projects/widgets/categories/category_list.dart';
import 'package:potential_aid_app/projects/widgets/project_list.dart';
import 'package:potential_aid_app/projects/widgets/search_bar.dart';

class ProjectCategoryListScreen extends ConsumerStatefulWidget {
  final bool initialShowCategories;

  const ProjectCategoryListScreen({super.key, this.initialShowCategories = true});

  @override
  ConsumerState<ProjectCategoryListScreen> createState() =>
      _ProjectCategoryListScreenState();
}

class _ProjectCategoryListScreenState
    extends ConsumerState<ProjectCategoryListScreen> {
  late bool showCategories;
  String query = '';
  String _categoryQuery = '';

  final GlobalKey<SearchAppBarState> _categoriesSearchBarKey =
      GlobalKey<SearchAppBarState>();
  final GlobalKey<SearchAppBarState> _projectsSearchBarKey =
      GlobalKey<SearchAppBarState>();

  @override
  void initState() {
    super.initState();
    showCategories = widget.initialShowCategories;
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
    if (event is KeyDownEvent && HardwareKeyboard.instance.isControlPressed) {
      if (event.logicalKey == LogicalKeyboardKey.keyF) {
        if (showCategories) {
          _categoriesSearchBarKey.currentState?.activateSearch();
        } else {
          _projectsSearchBarKey.currentState?.activateSearch();
        }
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyN) {
        if (showCategories) {
          showAddCategoryDialog(context);
        } else {
          showAddProjectDialog(context: context);
        }
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showCategories
          ? SearchAppBar(
              key: _categoriesSearchBarKey,
              normalTitle: 'Project Categories',
              titleStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 35),
              onSearchChanged: _onCategorySearchChanged,
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
              ),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            )
          : SearchAppBar(
              key: _projectsSearchBarKey,
              normalTitle: 'Projects',
              onSearchChanged: _onSearchChanged,
            ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dashboard_rounded),
                  Switch(
                    value: showCategories,
                    onChanged: (value) {
                      setState(() {
                        showCategories = !showCategories;
                        query = '';
                        _categoryQuery = '';
                      });
                    },
                  ),
                  Icon(Icons.category_rounded),
                ],
              ),
              Expanded(
                child: showCategories
                    ? CategoryList(searchQuery: _categoryQuery)
                    : ProjectList(searchQuery: query),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          showCategories
              ? FloatingActionButton.extended(
                  onPressed: () {
                    showAddCategoryDialog(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Icon(Icons.category),
                )
              : FloatingActionButton.extended(
                  onPressed: () {
                    showAddProjectDialog(context: context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Project'),
                ),
        ],
      ),
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      query = value.toLowerCase();
    });
  }

  void _onCategorySearchChanged(String value) {
    setState(() {
      _categoryQuery = value;
    });
  }
}
