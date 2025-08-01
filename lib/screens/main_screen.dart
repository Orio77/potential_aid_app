import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/widgets/add_task_dialog.dart';
import 'package:potential_aid_app/widgets/date_header.dart';
import 'package:potential_aid_app/widgets/schedule_list.dart';

// TODO: Task 6.2 - Add navigation UI elements to MainScreen
// STEPS:
// 1. Add "Projects" button to app bar actions
// 2. Ensure proper navigation to ProjectsScreen
// 3. Consider adding navigation drawer for future features
// 4. Update UI to show project context in task blocks (future task)

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Daily Schedule')),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // TODO: Task 6.2 - Add Projects button to app bar
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/projects');
            },
            icon: const Icon(Icons.folder_outlined),
            tooltip: 'Projects',
          ),
        ],
      ),
      body: Column(
        children: [
          const DateHeader(),
          Expanded(child: ScheduleList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddTaskDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
