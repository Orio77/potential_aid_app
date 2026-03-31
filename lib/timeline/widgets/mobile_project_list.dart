import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/models/project_interval.dart';
import 'package:potential_aid_app/projects/screens/project_screen.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:time_machine/time_machine.dart';

/// Mobile-friendly vertical list of projects for the timeline.
/// Replaces the horizontal Gantt bar chart on narrow screens (< 600 px).
class MobileProjectList extends ConsumerWidget {
  final List<ProjectInterval> projects;

  const MobileProjectList({super.key, required this.projects});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (projects.isEmpty) {
      return const Center(
        child: Text('No projects for this month'),
      );
    }

    final today = LocalDate.today();

    final overdue = projects
        .where((p) => p.endDay < today && (p.progress ?? 0) < 1.0)
        .toList()
      ..sort((a, b) => b.endDay.compareTo(a.endDay)); // most recently ended first

    final active = projects
        .where((p) => p.endDay >= today || (p.progress ?? 0) >= 1.0)
        .toList()
      ..sort((a, b) => a.endDay.compareTo(b.endDay)); // soonest deadline first

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        if (overdue.isNotEmpty) ...[
          _SectionHeader(label: 'Overdue', color: Colors.red.shade700),
          ...overdue.map((p) => _ProjectRow(interval: p)),
          const SizedBox(height: 8),
        ],
        if (active.isNotEmpty) ...[
          _SectionHeader(label: 'Active', color: Colors.green.shade700),
          ...active.map((p) => _ProjectRow(interval: p)),
        ],
      ],
    );
  }
}

// ── Section divider ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: color.withValues(alpha: 0.4), thickness: 1)),
        ],
      ),
    );
  }
}

// ── Single project row ───────────────────────────────────────────────────────

class _ProjectRow extends ConsumerWidget {
  final ProjectInterval interval;
  const _ProjectRow({required this.interval});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = interval.projectId != null
        ? ref.watch(projectProvider(interval.projectId!))
        : const AsyncValue<ProjectData?>.data(null);

    final today = LocalDate.today();
    final daysLeft = interval.endDay.epochDay - today.epochDay;
    final progress = (interval.progress ?? 0.0).clamp(0.0, 1.0);
    final isOverdue = daysLeft < 0 && progress < 1.0;
    final barColor = interval.color ?? Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final projectData = projectAsync.valueOrNull;
          if (projectData != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProjectScreen(data: projectData),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Colour dot
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: barColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Project name
                  Expanded(
                    child: Text(
                      interval.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Days label
                  Text(
                    _daysLabel(daysLeft, progress),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isOverdue ? Colors.red.shade700 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress bar + percentage
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        color: barColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _daysLabel(int daysLeft, double progress) {
    if (progress >= 1.0) return 'done';
    if (daysLeft == 0) return 'today';
    if (daysLeft < 0) return '${daysLeft.abs()}d overdue';
    return '${daysLeft}d left';
  }
}
