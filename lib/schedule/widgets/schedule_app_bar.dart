import 'package:flutter/material.dart';
import 'package:potential_aid_app/claude/screens/claude_suggestions_screen.dart';
import 'package:potential_aid_app/stats/screens/completion_stats_screen.dart';
import 'package:potential_aid_app/projects/screens/project_category_list_screen.dart';
import 'package:potential_aid_app/timeline/screens/timeline_screen.dart';
import 'package:potential_aid_app/pursuit/screens/pursuit_focus_screen.dart';
import 'package:potential_aid_app/widgets/sync/sync_button.dart';

class ScheduleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ScheduleAppBar({super.key, this.height = kToolbarHeight});

  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // M3 AppBar tints/darkens when body content scrolls ("scrolled under"); keep a flat bar.
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Pursuit focus',
              icon: const Icon(Icons.filter_3),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const PursuitFocusScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      leadingWidth: 120,
      leading: Row(
        children: [
          IconButton(
            icon: Icon(Icons.stacked_bar_chart),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CompletionStatsScreen(),
                ),
              );
            },
          ),
          SyncButton(),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ClaudeSuggestionsScreen(),
              ),
            );
          },
          icon: const Icon(Icons.auto_fix_high_outlined),
          tooltip: 'Claude suggestions',
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const TimelineScreen()),
            );
          },
          icon: const Icon(Icons.timeline_outlined),
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ProjectCategoryListScreen(),
              ),
            );
          },
          icon: const Icon(Icons.folder_outlined),
          tooltip: 'Projects',
        ),
      ],
    );
  }
}
