import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';

class DeleteProject extends ConsumerWidget {
  final ProjectData data;
  const DeleteProject({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () => _showDeleteDialog(context, ref),
      icon: Icon(Icons.delete),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _buildConfirmationDialog(context, ref, data.name),
    );
  }

  Widget _buildConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    String title,
  ) {
    final navigator = Navigator.of(context);

    return AlertDialog(
      title: Text('Delete Project'),
      content: Text(
        'Are you sure you want to delete "$title"? This action cannot be undone.',
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(onPressed: () => navigator.pop(), child: Text('Cancel')),
            TextButton(
              onPressed: () async {
                navigator.pop();
                await _deleteProject(data.id, ref);
                navigator.pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _deleteProject(int projectId, WidgetRef ref) async {
    await ref.read(projectsNotifierProvider.notifier).deleteProject(projectId);
    ref.invalidate(projectsNotifierProvider);
  }
}
