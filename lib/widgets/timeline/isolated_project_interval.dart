import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/project_intervals_notifier.dart';
import 'package:potential_aid_app/widgets/timeline/resizable_project_interval.dart';
import 'package:time_machine/time_machine.dart';

class IsolatedProjectInterval extends ConsumerWidget {
  final int projectId;
  final double dayCardWidth;
  final double projectBarHeight;
  final double handleWidth;
  final LocalDate timelineStart;
  final ScrollController? scrollController;

  const IsolatedProjectInterval({
    super.key,
    required this.projectId,
    required this.dayCardWidth,
    required this.projectBarHeight,
    required this.handleWidth,
    required this.timelineStart,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(individualProjectProvider(projectId));

    if (project == null) return const SizedBox.shrink();

    return ResizableProjectInterval(
      project: project,
      dayCardWidth: dayCardWidth,
      projectBarHeight: projectBarHeight,
      handleWidth: handleWidth,
      timelineStart: timelineStart,
      scrollController: scrollController,
      onProjectUpdated: (updatedProject) async {
        await ref
            .read(projectIntervalsNotifierProvider.notifier)
            .persistProjectUpdate(updatedProject);
      },
    );
  }
}
