import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/projects/widgets/add_project_dialog.dart';
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

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SearchAppBar(
        normalTitle: 'Projects',
        searchHint: 'Search projects...',
        onSearchChanged: _onSearchChanged,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ProjectList(
            searchQuery: _searchQuery,
            category: widget.categoryId,
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
