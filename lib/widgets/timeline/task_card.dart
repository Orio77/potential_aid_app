import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:potential_aid_app/utils/color_utils.dart';

class TaskCard extends ConsumerWidget {
  final TaskData task;
  final double width;
  final double? height;

  const TaskCard({
    super.key,
    required this.task,
    required this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider(task.projectId));

    return project.when(
      data: (ProjectData? project) => _buildTaskCard(
        (project == null || project.color == null)
            ? Colors.lightBlueAccent.toARGB32()
            : project.color!,
      ),
      error: (error, stackTrace) => Text("Error: $error"),
      loading: () => const CircularProgressIndicator(),
    );
  }

  Container _buildTaskCard(int projectColorCode) {
    return Container(
      width: width,
      height: height ?? 60,
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: ColorUtils.createNorthernLightsGradient(
          baseColor: Color(projectColorCode),
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsetsGeometry.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              task.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
