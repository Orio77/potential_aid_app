/*
 * PROJECTS SCREEN IMPLEMENTATION
 * 
 * This screen displays a list/grid of project cards and allows users to manage their projects.
 * Each project card shows basic information including name, deadline, task count, and progress.
 * 
 * CONTEXT: This is the main screen for the projects feature (Phase 2). Users will navigate
 * here from the main schedule screen to view and manage their projects.
 * 
 * ARCHITECTURE: Follows Flutter best practices with widget composition. Uses Riverpod for
 * state management and follows the same patterns established in MainScreen.
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Task 4.1 - Create ProjectsScreen widget
// STEPS:
// 1. Create StatelessWidget extending ConsumerWidget for Riverpod integration
// 2. Implement app bar with title "Projects" and back button
// 3. Add search/filter functionality for projects (optional for first iteration)
// 4. Handle empty state when no projects exist with helpful message
// 5. Implement proper scrolling with RefreshIndicator
// 6. Add error handling for loading failures

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        // TODO: Add search icon and functionality later
      ),
      body: const Column(
        children: [
          // TODO: Add search bar widget here (future task)
          Expanded(child: ProjectsList()),
        ],
      ),
      floatingActionButton: const AddProjectButton(),
    );
  }
}

// TODO: Task 4.4 - Implement project cards grid/list layout
// STEPS:
// 1. Create ProjectsList widget to display project cards
// 2. Use responsive layout (GridView.builder for tablets, ListView for phones)
// 3. Add proper spacing and margins
// 4. Handle different screen sizes with MediaQuery
// 5. Implement pull-to-refresh functionality
// 6. Add loading and error states

class ProjectsList extends ConsumerWidget {
  const ProjectsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Watch projects provider and handle states
    // final projectsAsync = ref.watch(projectsNotifierProvider);

    // TODO: Return different widgets based on state:
    // - Loading: CircularProgressIndicator
    // - Error: Error message with retry button
    // - Empty: EmptyProjectsWidget
    // - Data: GridView/ListView with ProjectCard widgets

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No projects yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the + button to create your first project',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// TODO: Task 4.2 - Create ProjectCard widget
// STEPS:
// 1. Create widget to display individual project information
// 2. Show project name prominently with proper typography
// 3. Display start date and deadline with calendar icons
// 4. Show task count and completion percentage with progress indicator
// 5. Add visual deadline warning (red for overdue, orange for soon due)
// 6. Make card tappable with Material ripple effect
// 7. Use Card widget with elevation for nice appearance

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

// TODO: Task 4.3 - Create AddProjectButton widget
// STEPS:
// 1. Create floating action button for adding new projects
// 2. Use consistent styling with existing UI (follow AddTaskButton pattern)
// 3. Open project creation dialog when tapped
// 4. Add proper accessibility labels

class AddProjectButton extends StatelessWidget {
  const AddProjectButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // TODO: Task 5.1 - Open AddProjectDialog
        showDialog(
          context: context,
          builder: (context) => const AddProjectDialog(),
        );
      },
      tooltip: 'Add Project',
      child: const Icon(Icons.add),
    );
  }
}

// TODO: Task 5.1 - Create AddProjectDialog widget
// STEPS:
// 1. Create dialog for adding new projects
// 2. Add input field for project name with validation
// 3. Add date picker for deadline (required)
// 4. Add optional start date picker (defaults to today)
// 5. Add save button with loading state
// 6. Implement proper error handling and validation messages
// 7. Close dialog and refresh projects list on success

class AddProjectDialog extends StatefulWidget {
  const AddProjectDialog({super.key});

  @override
  State<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<AddProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _deadline;
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate() || _deadline == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Call projects notifier to save project
      // await ref.read(projectsNotifierProvider.notifier).addProject(
      //   _nameController.text,
      //   _deadline!,
      //   startDate: _startDate,
      // );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating project: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Project'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                hintText: 'Enter project name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a project name';
                }
                if (value.trim().length < 3) {
                  return 'Project name must be at least 3 characters';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectStartDate,
                    child: Text(
                      'Start: ${_startDate.day}/${_startDate.month}/${_startDate.year}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectDeadline,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _deadline == null ? Colors.red : Colors.grey,
                      ),
                    ),
                    child: Text(
                      _deadline == null
                          ? 'Select Deadline *'
                          : 'Due: ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                      style: TextStyle(
                        color: _deadline == null ? Colors.red : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_deadline == null)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Deadline is required',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProject,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
