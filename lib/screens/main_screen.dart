import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/widgets/add_block_dialog.dart';
import 'package:potential_aid_app/widgets/date_header.dart';
import 'package:potential_aid_app/widgets/schedule_list.dart';

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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddBlockDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
