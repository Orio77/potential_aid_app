import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:potential_aid_app/widgets/projects/project_card.dart';

class ProjectList extends ConsumerStatefulWidget {
  const ProjectList({super.key});

  @override
  ConsumerState<ProjectList> createState() => _ProjectListState();
}

class _ProjectListState extends ConsumerState<ProjectList> {
  bool showCompleted = false;

  Widget _buildEmptyState() {
    return Text("State is Empty");
  }

  Widget _buildProjectList(List<ProjectData> projects) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_outlined, size: 30),

            Switch(
              value: showCompleted,
              onChanged: (bool newValue) {
                setState(() {
                  showCompleted = newValue;
                });
                _updatePredicates();
              },
            ),
            Icon(Icons.archive_sharp, size: 30),
          ],
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount;
              double childAspectRatio;

              if (constraints.maxWidth < 600) {
                crossAxisCount = 1;
                childAspectRatio = 2.5;
              } else if (constraints.maxWidth < 900) {
                crossAxisCount = 2;
                childAspectRatio = 1.3;
              } else {
                crossAxisCount = 3;
                childAspectRatio = 1.0;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return ProjectCard(projectId: project.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _updatePredicates() {
    final notifier = ref.read(projectsNotifierProvider.notifier);

    if (showCompleted) {
      notifier.setPredicates([
        (table) => (table.current.isBiggerThan(table.goal)),
      ]);
    } else {
      notifier.setPredicates([
        (table) =>
            table.current.isNull() |
            table.goal.isNull() |
            (table.current.isSmallerOrEqual(table.goal)),
      ]);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePredicates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectsData = ref.watch(projectsNotifierProvider);

    return projectsData.isEmpty
        ? _buildEmptyState()
        : _buildProjectList(projectsData);
  }
}
