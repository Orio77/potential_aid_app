import 'package:flutter/material.dart';

class TaskBreakdownScreen extends StatelessWidget {
  final int taskId;
  const TaskBreakdownScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Text("Task Break Down for task $taskId!"),
    );
  }
}
