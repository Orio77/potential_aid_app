import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/project_search_notifier.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:potential_aid_app/widgets/util/search_text_field.dart';

class LinkProjectDialog extends ConsumerStatefulWidget {
  final int projectId;
  const LinkProjectDialog({super.key, required this.projectId});

  @override
  ConsumerState<LinkProjectDialog> createState() => _LinkProjectDialogState();
}

class _LinkProjectDialogState extends ConsumerState<LinkProjectDialog> {
  int? selectedProjectId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Link Project"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Search and select a project to link:'),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SearchTextField(
                labelText: "Search projects",
                searchProvider: projectSearchProvider,
                getDisplayText: (ProjectData item) => item.name,
                onItemSelected: (ProjectData item) {
                  setState(() {
                    selectedProjectId = item.id;
                  });
                },
                predicates: [
                  (ProjectData p) => p.id != widget.projectId,
                  (ProjectData p) => p.parentProjectId != widget.projectId,
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: selectedProjectId != null && !_isLoading
              ? _linkProject
              : null,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Link'),
        ),
      ],
    );
  }

  Future<void> _linkProject() async {
    if (selectedProjectId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final projectsNotifier = ref.read(projectsNotifierProvider.notifier);

      await projectsNotifier.moveProject(selectedProjectId!, widget.projectId);

      ref.invalidate(descendantProjectProvider(widget.projectId));

      if (mounted) {
        Navigator.of(context).pop(selectedProjectId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error linking project: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

Future<int?> showLinkProjectDialog(BuildContext context, int projectId) async {
  return await showDialog<int>(
    context: context,
    builder: (context) => LinkProjectDialog(projectId: projectId),
  );
}
