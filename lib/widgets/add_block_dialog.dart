/*
 * ADD BLOCK DIALOG WIDGET
 * 
 * This is the main dialog component for creating time blocks with project-based task selection.
 * Unlike the existing AddTaskDialog which creates individual tasks, this dialog allows users to:
 * 1. Select a project from a dropdown
 * 2. Search and select multiple tasks from that project
 * 3. Create a time block containing those tasks
 * 
 * Key differences from AddTaskDialog:
 * - Project selection comes first
 * - Multiple task selection instead of single task creation
 * - Tasks are chosen from existing project tasks, not created new
 * - Support for multiple tasks per time block using position_in_block
 * 
 * This component integrates with:
 * - ProjectsNotifier for project list
 * - Database task search methods (to be implemented in database_tasks.dart)
 * - ScheduleNotifier for block creation with multiple tasks
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:potential_aid_app/providers/schedule_notifier.dart';
import 'package:potential_aid_app/providers/settings_notifier.dart';
import 'package:potential_aid_app/widgets/duration_picker_dialog.dart';

class AddBlockDialog extends ConsumerStatefulWidget {
  const AddBlockDialog({super.key});

  @override
  ConsumerState<AddBlockDialog> createState() => _AddBlockDialogState();
}

class _AddBlockDialogState extends ConsumerState<AddBlockDialog> {
  // TODO: Add form key for validation
  // final _formKey = GlobalKey<FormState>();

  // TODO: Add project selection state
  // ProjectData? _selectedProject;

  // TODO: Add selected tasks state  
  // List<TaskData> _selectedTasks = [];

  // TODO: Add task search controller and focus node
  // final _taskSearchController = TextEditingController();
  // final _taskSearchFocusNode = FocusNode();

  // TODO: Add time and duration state (similar to AddTaskDialog)
  // late TimeOfDay _startTime;
  // int _durationMinutes = 60;

  // TODO: Add loading and error state
  // bool _isLoading = false;
  // String? _errorMessage;

  // TODO: Add search suggestions state
  // bool _showTaskSuggestions = false;
  // List<TaskData> _taskSuggestions = [];

  @override
  void initState() {
    super.initState();
    // TODO: Initialize start time from settings (copy from AddTaskDialog)
    // TODO: Initialize default duration from settings
    // TODO: Setup focus node for task search
  }

  @override
  void dispose() {
    // TODO: Dispose controllers and focus nodes
    super.dispose();
  }

  // TODO: Implement _calculateNextAvailableTime method
  // Copy from AddTaskDialog but adapt for block creation

  // TODO: Implement _onProjectSelected method
  // - Clear selected tasks when project changes
  // - Clear task search field
  // - Hide suggestions

  // TODO: Implement _searchTasksInProject method  
  // - Use database_tasks.dart searchTasksInProject method
  // - Update _taskSuggestions state
  // - Show/hide suggestions based on results

  // TODO: Implement _addTaskToSelection method
  // - Add task to _selectedTasks if not already selected
  // - Remove from suggestions
  // - Clear search field
  // - Show selected tasks list

  // TODO: Implement _removeTaskFromSelection method
  // - Remove task from _selectedTasks
  // - Update UI

  // TODO: Implement _createBlock method
  // - Validate that project is selected
  // - Validate that at least one task is selected
  // - Calculate time slots based on number of tasks and duration
  // - Create block entries for each task with position_in_block
  // - Use ScheduleNotifier to save blocks

  // TODO: Implement build method with:
  // - Project dropdown (searchable)
  // - Task search field with suggestions
  // - Selected tasks chips/list
  // - Time and duration pickers (copy from AddTaskDialog)
  // - Create Block button
  // - Error handling display

  @override
  Widget build(BuildContext context) {
    // TODO: Implement the full UI
    // Structure should be:
    // AlertDialog(
    //   title: Text('Add Time Block'),
    //   content: Column([
    //     ProjectDropdown(),
    //     TaskSearchField(),
    //     TaskSuggestionsList(),
    //     SelectedTasksList(), 
    //     TimePickerRow(),
    //     DurationPickerRow(),
    //     ErrorDisplay(),
    //   ]),
    //   actions: [Cancel, Create Block buttons]
    // )
    
    return AlertDialog(
      title: const Text('Add Time Block'),
      content: const Text('TODO: Implement full dialog UI'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Call _createBlock method
            Navigator.of(context).pop();
          },
          child: const Text('Create Block'),
        ),
      ],
    );
  }
}

// TODO: Create showAddBlockDialog function
// Similar to showAddTaskDialog in add_task_dialog.dart
// Future<void> showAddBlockDialog(BuildContext context) async {
//   await showDialog(
//     context: context,
//     builder: (context) => const AddBlockDialog(),
//   );
// }
