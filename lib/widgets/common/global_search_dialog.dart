import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/breakdown/screens/task_breakdown_screen.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/projects/screens/project_screen.dart';
import 'package:potential_aid_app/providers/project_search_notifier.dart';
import 'package:potential_aid_app/providers/task_search_notifier.dart';

class GlobalSearchDialog extends ConsumerStatefulWidget {
  const GlobalSearchDialog({super.key});

  @override
  ConsumerState<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends ConsumerState<GlobalSearchDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    ref.read(taskSearchProvider.notifier).search(query);
    ref.read(projectSearchProvider.notifier).search(query);
    setState(() {});
  }

  void _openProject(ProjectData project) {
    Navigator.of(context).pop();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ProjectScreen(data: project)));
  }

  void _openTask(TaskData task) {
    Navigator.of(context).pop();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TaskBreakdownScreen(task: task)));
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectSearchProvider);
    final tasks = ref.watch(taskSearchProvider);
    final hasQuery = _controller.text.trim().isNotEmpty;
    final hasResults = projects.isNotEmpty || tasks.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search tasks and projects...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: _onChanged,
          ),
        ),
        Flexible(child: _buildResults(projects, tasks, hasQuery, hasResults)),
      ],
    );
  }

  Widget _buildResults(
    List<ProjectData> projects,
    List<TaskData> tasks,
    bool hasQuery,
    bool hasResults,
  ) {
    if (!hasQuery) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text(
          'Start typing to search...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (!hasResults) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text('No results found.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView(
      shrinkWrap: true,
      children: [
        if (projects.isNotEmpty) ...[
          const _SectionHeader(label: 'PROJECTS'),
          ...projects.map(
            (p) => ListTile(
              dense: true,
              leading: const Icon(Icons.folder_outlined),
              title: Text(p.name),
              onTap: () => _openProject(p),
            ),
          ),
        ],
        if (tasks.isNotEmpty) ...[
          const _SectionHeader(label: 'TASKS'),
          ...tasks.map(
            (t) => ListTile(
              dense: true,
              leading: const Icon(Icons.task_alt_outlined),
              title: Text(t.name, overflow: TextOverflow.ellipsis),
              trailing: t.depth > 0 ? _DepthBadge(depth: t.depth) : null,
              onTap: () => _openTask(t),
            ),
          ),
        ],
      ],
    );
  }
}

class _DepthBadge extends StatelessWidget {
  final int depth;
  const _DepthBadge({required this.depth});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'L$depth',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
