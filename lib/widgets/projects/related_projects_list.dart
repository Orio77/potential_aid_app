import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:potential_aid_app/widgets/projects/project_progress_info.dart';

class RelatedProjectsList extends ConsumerWidget {
  const RelatedProjectsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<ProjectData?>>(
      future: Future.wait([
        ref.read(projectProvider(2).future),
        ref.read(projectProvider(3).future),
        ref.read(projectProvider(4).future),
        ref.read(projectProvider(5).future),
        ref.read(projectProvider(6).future),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final projects =
            snapshot.data
                ?.where((p) => p != null)
                .cast<ProjectData>()
                .toList() ??
            [];

        return Container(
          height: ((projects.length / 3).ceil() * 120.0) + 50.0,
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Related Projects',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                          childAspectRatio: 2.0,
                        ),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ProjectProgressInfo(project: projects[index]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
