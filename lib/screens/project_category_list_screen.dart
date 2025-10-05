import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/widgets/projects/add_project_dialog.dart';
import 'package:potential_aid_app/widgets/projects/categories/add_category_dialog.dart';
import 'package:potential_aid_app/widgets/projects/categories/category_list.dart';
import 'package:potential_aid_app/widgets/projects/project_list.dart';
import 'package:potential_aid_app/widgets/projects/search_bar.dart';

class ProjectCategoryListScreen extends ConsumerStatefulWidget {
  const ProjectCategoryListScreen({super.key});

  @override
  ConsumerState<ProjectCategoryListScreen> createState() =>
      _ProjectCategoryListScreenState();
}

class _ProjectCategoryListScreenState
    extends ConsumerState<ProjectCategoryListScreen> {
  late bool showCategories;
  String query = "";

  @override
  void initState() {
    super.initState();
    showCategories = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showCategories
          ? AppBar(
              title: Text(
                'Project Categories',
                style: TextStyle(fontWeight: FontWeight.w400, fontSize: 35),
              ),
              centerTitle: true,
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
              ),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            )
          : SearchAppBar(
              normalTitle: "Projects",
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
                        query = "";
                      });
                    },
                  ),
                  Icon(Icons.category_rounded),
                ],
              ),
              Expanded(
                child: showCategories
                    ? CategoryList()
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
}
