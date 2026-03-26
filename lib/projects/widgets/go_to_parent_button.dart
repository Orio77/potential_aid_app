import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:potential_aid_app/projects/screens/project_screen.dart';

class GoToParentButton extends ConsumerWidget {
  final int parentId;
  const GoToParentButton({super.key, required this.parentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () async => _pushParentScreenReplacement(
        context,
        ref,
        Navigator.of(context),
        parentId,
      ),
      icon: Icon(Icons.person_pin),
    );
  }

  Future<void> _pushParentScreenReplacement(
    BuildContext context,
    WidgetRef ref,
    NavigatorState navigator,
    int parentId,
  ) async {
    final parentData = await ref
        .read(projectsNotifierProvider.notifier)
        .getProjectById(parentId);

    navigator.pushReplacement(
      MaterialPageRoute(builder: (context) => ProjectScreen(data: parentData!)),
    );
  }
}
