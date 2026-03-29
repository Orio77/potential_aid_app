import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter/services.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/projects/widgets/project_task_list_data.dart';
import 'package:potential_aid_app/projects/widgets/search_bar.dart';

class ProjectTaskList extends StatefulWidget {
  final int projectId;
  final bool isEditMode;
  final void Function(bool) onEditModeChanged;
  final void Function(List<TaskData>) onSelectionChanged;

  const ProjectTaskList({
    super.key,
    required this.isEditMode,
    required this.projectId,
    required this.onEditModeChanged,
    required this.onSelectionChanged,
  });

  @override
  State<ProjectTaskList> createState() => _ProjectTaskListState();
}

class _ProjectTaskListState extends State<ProjectTaskList> {
  late bool unwinded;
  late bool editMode;
  bool _showCompleted = false;
  String? curQuery;
  int? curDepth;
  late TextEditingController _controller;
  List<TaskData> selectedTasks = [];

  @override
  void initState() {
    super.initState();
    editMode = widget.isEditMode;
    unwinded = false;
    _controller = TextEditingController();
  }

  @override
  void didUpdateWidget(ProjectTaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditMode != oldWidget.isEditMode) {
      setState(() {
        editMode = widget.isEditMode;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          child: unwinded ? _buildUnwindedView() : _buildWindedView(),
        ),
        ProjectTaskListData(
          projectId: widget.projectId,
          selectedTasks: selectedTasks,
          query: curQuery,
          depthLevel: curDepth,
          editMode: editMode,
          showCompleted: _showCompleted,
          onSelectionChanged: (tasks) => setState(() {
            selectedTasks = tasks;
            widget.onSelectionChanged(selectedTasks);
          }),
        ),
      ],
    );
  }

  Widget _buildWindedView() {
    return Container(
      height: 28.0,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          // Expand toolbar
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(8),
              ),
              onTap: () => setState(() => unwinded = true),
              child: Center(
                child: Icon(
                  Icons.expand_more_rounded,
                  color: Colors.grey.shade600,
                  size: 18,
                ),
              ),
            ),
          ),
          Container(width: 1, color: Colors.grey.shade300),
          // Show/hide completed — always accessible
          SizedBox(
            width: 40,
            height: 28,
            child: IconButton(
              icon: Icon(
                _showCompleted
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                size: 15,
                color: _showCompleted
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade500,
              ),
              onPressed: () =>
                  setState(() => _showCompleted = !_showCompleted),
              tooltip:
                  _showCompleted ? 'Hide completed' : 'Show completed',
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnwindedView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SizedBox(
            width: 300,
            child: SearchBar(
              normalTitle: 'Search tasks',
              onSearchChanged: (query) {
                setState(() {
                  curQuery = query;
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: TextField(
            controller: _controller,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Depth',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
            ),
            onChanged: (value) {
              setState(() {
                curDepth = int.tryParse(value);
              });
            },
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Show/hide completed
            IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                _showCompleted
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: _showCompleted
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onPressed: () =>
                  setState(() => _showCompleted = !_showCompleted),
              tooltip:
                  _showCompleted ? 'Hide completed' : 'Show completed',
            ),
            IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  editMode = !editMode;
                  widget.onEditModeChanged(editMode);
                });
              },
              icon: Icon(
                editMode ? Icons.done_rounded : Icons.edit_note_rounded,
              ),
            ),
            if (editMode)
              IconButton(
                onPressed: () => setState(() {
                  selectedTasks.clear();
                  widget.onSelectionChanged(selectedTasks);
                }),
                icon: const Icon(Icons.clear),
              ),
            IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _controller.clear();
                  curDepth = null;
                  curQuery = null;
                  unwinded = !unwinded;
                });
              },
              icon: const Icon(Icons.expand_less_rounded),
            ),
          ],
        ),
      ],
    );
  }
}
