import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/widgets/add_task_dialog.dart';
import 'package:potential_aid_app/widgets/date_header.dart';
import 'package:potential_aid_app/widgets/schedule_list.dart';
// TODO: Import the add block dialog once implemented
// import 'package:potential_aid_app/widgets/add_block_dialog.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Daily Schedule')),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // TODO: Add Block Button - implement this after add_block_dialog.dart is complete
          // This button should open the Add Block Dialog for creating time blocks with multiple tasks
          // FloatingActionButton(
          //   heroTag: "addBlock",
          //   onPressed: () {
          //     showAddBlockDialog(context);
          //   },
          //   backgroundColor: Colors.blue,
          //   child: const Icon(Icons.view_agenda),
          //   tooltip: 'Add Time Block',
          // ),
          // const SizedBox(height: 16),
          
          // Existing Add Task Button
          FloatingActionButton(
            heroTag: "addTask",
            onPressed: () {
              showAddTaskDialog(context);
            },
            child: const Icon(Icons.add),
            tooltip: 'Add Single Task',
          ),
        ],
      ),
    );
  }
}
