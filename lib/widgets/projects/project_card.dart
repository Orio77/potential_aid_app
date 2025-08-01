import 'package:flutter/material.dart';

class ProjectCard extends StatelessWidget {
  // TODO: Add project data parameter
  // final ProjectWithStats project;

  const ProjectCard({
    super.key,
    // required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          // TODO: Task 6.3 - Handle project card tap (placeholder)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Coming Soon: Project Details'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TODO: Replace with actual project data
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sample Project', // project.name
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // TODO: Add deadline warning icon based on urgency
                  const Icon(Icons.schedule, size: 16, color: Colors.orange),
                ],
              ),
              const SizedBox(height: 8),
              // TODO: Display actual dates
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: Dec 31, 2024', // Format project.deadline
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // TODO: Display actual task count and progress
              Row(
                children: [
                  const Icon(Icons.task_alt, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '5 tasks', // project.taskCount
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    '60%', // project.completionPercentage
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // TODO: Replace with actual progress indicator
              LinearProgressIndicator(
                value: 0.6, // project.completionPercentage / 100
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
