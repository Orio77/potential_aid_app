import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/project_search_notifier.dart';
import 'package:potential_aid_app/widgets/util/search_text_field.dart';

class SelectProjectDialog extends ConsumerStatefulWidget {
  const SelectProjectDialog({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SelectProjectDialogState();
}

class _SelectProjectDialogState extends ConsumerState<SelectProjectDialog> {
  ProjectData? _selectedProject;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _selectedProject != null
            ? "Select Project:  ${_selectedProject!.name}"
            : "Select Project",
      ),
      content: SizedBox(
        width: 250,
        height: 300,
        child: Column(
          children: [
            SearchTextField(
              labelText: "search projects...",
              searchProvider: projectSearchProvider,
              getDisplayText: (ProjectData project) => project.name,
              onItemSelected: (ProjectData project) => setState(() {
                _selectedProject = project;
              }),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text("cancel"),
        ),
        ElevatedButton(
          onPressed: _selectedProject == null
              ? null
              : () {
                  Navigator.of(context).pop(_selectedProject);
                },
          child: const Text("OK"),
        ),
      ],
    );
  }
}

Future<ProjectData?> showSelectProjectDialog(BuildContext context) async {
  return await showDialog(
    context: context,
    builder: (context) {
      return SelectProjectDialog();
    },
  );
}
