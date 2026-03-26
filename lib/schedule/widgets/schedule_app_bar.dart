import 'package:flutter/material.dart';
import 'package:potential_aid_app/screens/completion_stats_screen.dart';
import 'package:potential_aid_app/projects/screens/project_category_list_screen.dart';
import 'package:potential_aid_app/screens/timeline_screen.dart';
import 'package:potential_aid_app/widgets/sync/sync_button.dart';

class ScheduleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ScheduleAppBar({super.key, this.height = kToolbarHeight});

  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          'Daily Schedule',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
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
              MaterialPageRoute(builder: (context) => const TimelineScreen()),
            );
          },
          icon: Icon(Icons.timeline_outlined),
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
