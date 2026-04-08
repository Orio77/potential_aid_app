import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:potential_aid_app/projects/screens/project_screen.dart';
import 'package:potential_aid_app/projects/widgets/project_progress_info.dart';

class RelatedProjectsList extends ConsumerStatefulWidget {
  final int projectId;
  const RelatedProjectsList({super.key, required this.projectId});

  @override
  ConsumerState<RelatedProjectsList> createState() =>
      _RelatedProjectsListState();
}

class _RelatedProjectsListState extends ConsumerState<RelatedProjectsList> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(descendantProjectProvider(widget.projectId));

    return projects.when(
      data: (data) {
        if (data.isEmpty) return const SizedBox.shrink();
        final filtered = _showCompleted
            ? data
            : data.where((p) => p.current < p.goal).toList();
        return _buildDescendantProjectList(data, filtered);
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => Text("Error: $error"),
    );
  }

  Widget _buildDescendantProjectList(
    List<ProjectData> allProjects,
    List<ProjectData> filtered,
  ) {
    // Card has default margin (~4dp each side); Container also has padding — inner
    // Column height must fit the header row + grid / empty state without overflowing.
    const chromeBelowGrid = 120.0;
    // Taller cells than aspect 2.0 so [ProjectProgressInfo] fits (title + stats + bar).
    const gridRowExtent = 172.0;
    return Container(
      height: ((filtered.length / 2).ceil() * gridRowExtent) + chromeBelowGrid,
      padding: const EdgeInsets.all(8.0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Related Projects',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Completed',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Switch(
                        value: _showCompleted,
                        onChanged: (value) =>
                            setState(() => _showCompleted = value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No active projects',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 1.52,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProjectScreen(data: filtered[index]),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: ProjectProgressInfo(
                                project: filtered[index],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
