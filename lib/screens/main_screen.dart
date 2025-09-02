import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/screens/project_list_screen.dart';
import 'package:potential_aid_app/screens/stats_screen.dart';
import 'package:potential_aid_app/widgets/add_block_dialog.dart';
import 'package:potential_aid_app/widgets/date_header.dart';
import 'package:potential_aid_app/widgets/schedule_list.dart';
import 'package:potential_aid_app/widgets/stats/schedule_progress_bar.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'Daily Schedule',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 30),
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: Icon(Icons.stacked_bar_chart),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const StatsScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProjectListScreen(),
                ),
              );
            },
            icon: const Icon(Icons.folder_outlined),
            tooltip: 'Projects',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: const [
              DateHeader(),
              SizedBox(height: 8),
              ScheduleProgressBar(),
              SizedBox(height: 16),
              Expanded(child: ScheduleList()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showAddBlockDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Block'),
      ),
    );
  }
}
