import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/widgets/add_task_dialog.dart';
import 'package:potential_aid_app/widgets/projects/project_task_list.dart';
import 'package:time_machine/time_machine.dart';

class ProjectScreen extends ConsumerWidget {
  final ProjectData data;

  const ProjectScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("${data.name} Project")),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios),
        ),
      ),
      body: Column(
        children: [
          Text('${data.current} / ${data.goal} ${data.unit}'),
          Text(
            'Start Date: ${LocalDate.dateTime(data.startDate).toString('dd-MM-yyyy')}',
          ),
          Text(
            'Deadline: ${LocalDate.dateTime(data.deadline).toString('dd-MM-yyyy')}',
          ),
          ProjectTaskList(projectId: data.id),
        ],
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () => showAddTaskDialog(context, data.id),
        child: Icon(Icons.add_task),
      ),
    );
  }
}
