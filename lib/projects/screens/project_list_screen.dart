import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter/services.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SearchAppBar(
        key: _searchBarKey,
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
