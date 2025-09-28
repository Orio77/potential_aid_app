import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/widgets/projects/add_project_dialog.dart';
import 'package:potential_aid_app/widgets/projects/project_list.dart';

class ProjectListScreen extends ConsumerStatefulWidget {
  final int? categoryId;

  const ProjectListScreen({super.key, this.categoryId});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search projects...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 18),
                onChanged: (query) {
                  setState(() {});
                },
              )
            : const Text(
                'Projects',
                style: TextStyle(fontWeight: FontWeight.w400, fontSize: 35),
              ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(_isSearching ? Icons.close : Icons.search),
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ProjectList(
            searchQuery: _searchController.text.toLowerCase(),
            category: widget.categoryId,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showAddProjectDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Project'),
      ),
    );
  }
}
