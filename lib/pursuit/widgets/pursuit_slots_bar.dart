import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/projects/screens/project_screen.dart';
import 'package:potential_aid_app/pursuit/models/pursuit_focus_state.dart';
import 'package:potential_aid_app/pursuit/providers/pursuit_focus_notifier.dart';
import 'package:potential_aid_app/pursuit/widgets/pursuit_colors.dart';
import 'package:potential_aid_app/pursuit/widgets/pursuit_pickers.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';

/// Pinned bottom bar showing the three active project slots.
class PursuitSlotsBar extends ConsumerWidget {
  const PursuitSlotsBar({
    super.key,
    required this.pursuit,
    required this.projects,
  });

  final PursuitFocusState pursuit;
  final List<ProjectData> projects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < PursuitFocusState.slotCount; i++) ...[
                Expanded(
                  child: PursuitSlotTile(
                    slotIndex: i,
                    projectId: pursuit.slots[i],
                    projects: projects,
                  ),
                ),
                if (i < PursuitFocusState.slotCount - 1)
                  const VerticalDivider(width: 1),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A single slot card inside [PursuitSlotsBar].
class PursuitSlotTile extends ConsumerWidget {
  const PursuitSlotTile({
    super.key,
    required this.slotIndex,
    required this.projectId,
    required this.projects,
  });

  final int slotIndex;
  final int? projectId;
  final List<ProjectData> projects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = slotColor(slotIndex, projectId, projects);

    // Only show projects that are still active and not deleted.
    final project = projectId != null ? findProject(projectId!, projects) : null;
    final hasProject = project != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Accent bar
        Container(height: 4, color: color),

        // Tapping the info area navigates to the project screen.
        InkWell(
          onTap: hasProject
              ? () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProjectScreen(data: project),
                    ),
                  )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Slot ${slotIndex + 1}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  project?.name ?? 'Empty',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasProject
                        ? null
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (hasProject && project.goal > 0) ...[
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (project.current / project.goal).clamp(0.0, 1.0),
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.2),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  Text(
                    '${project.current} / ${project.goal}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Action icons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SmallIconButton(
              icon: Icons.swap_horiz,
              tooltip: 'Choose project',
              onPressed: () async {
                final id = await showProjectPicker(context, ref);
                if (!context.mounted) return;
                await ref
                    .read(pursuitFocusNotifierProvider.notifier)
                    .setSlot(slotIndex, id);
              },
            ),
            if (hasProject) ...[
              _SmallIconButton(
                icon: Icons.check_circle_outline,
                tooltip: 'Mark project complete',
                onPressed: () =>
                    _confirmCompleteProject(context, ref, project),
              ),
              _SmallIconButton(
                icon: Icons.close,
                tooltip: 'Clear slot',
                onPressed: () => ref
                    .read(pursuitFocusNotifierProvider.notifier)
                    .setSlot(slotIndex, null),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _confirmCompleteProject(
    BuildContext context,
    WidgetRef ref,
    ProjectData project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete project?'),
        content: Text(
          'Mark "${project.name}" as completed '
          '(${project.current} → ${project.goal})?\n\n'
          'The next queued project will move into this slot.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(projectsNotifierProvider.notifier).updateProject(
          project.id,
          ProjectCompanion(current: Value(project.goal)),
        );
    await ref
        .read(pursuitFocusNotifierProvider.notifier)
        .onProjectProgressChanged(project.id);
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: tooltip,
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }
}
