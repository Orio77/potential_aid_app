import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/tasks_notifier.dart';

class CreationStatsScreen extends ConsumerStatefulWidget {
  const CreationStatsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreationStatsScreenState();
}

class _CreationStatsScreenState extends ConsumerState<CreationStatsScreen> {
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    final currentDate = selectedDate ?? DateTime.now();
    final taskCount = ref.watch(taskCountForDateProvider(currentDate));
    final projectCount = ref.watch(projectCountForDateProvider(currentDate));
    final year = currentDate.year;
    final month = currentDate.month;
    final day = currentDate.day;

    return Scaffold(
      appBar: AppBar(
        title: Text('Creation Stats for $day/$month/$year'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: taskCount.when(
        data: (count) {
          return _buildTaskCountWidget(count, projectCount.value ?? 0);
        },
        loading: () {
          return const CircularProgressIndicator();
        },
        error: (error, stack) {
          return Center(child: Text('Error: $error'));
        },
      ),
    );
  }

  Widget _buildTaskCountWidget(int taskCount, int projectCount) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () async {
              DateTime? pickedDate = await _selectDate(context);
              setState(() {
                selectedDate = pickedDate;
              });
            },
            icon: Icon(Icons.calendar_month),
          ),
          Text(
            'Tasks created today: $taskCount\nProjects created today: $projectCount',
            style: TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }

  Future<DateTime> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
    return picked ?? DateTime.now();
  }
}
