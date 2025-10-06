import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter/services.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/widgets/projects/project_task_list_data.dart';
import 'package:potential_aid_app/widgets/projects/search_bar.dart';

class ProjectTaskList extends StatefulWidget {
  final int projectId;
  final void Function(bool) onEditModeChanged;
  final void Function(List<TaskData>) onSelectionChanged;

  const ProjectTaskList({
    super.key,
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
  String? curQuery;
  int? curDepth;
  late TextEditingController _controller;
  List<TaskData> selectedTasks = [];

  @override
  void initState() {
    super.initState();
    editMode = false;
    unwinded = false;
    _controller = TextEditingController();
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
          padding: EdgeInsets.all(8.0),
          child: unwinded ? _buildUnwindedView() : _buildWindedView(),
        ),
        ProjectTaskListData(
          projectId: widget.projectId,
          selectedTasks: selectedTasks,
          query: curQuery,
          depthLevel: curDepth,
          editMode: editMode,
          onSelectionChanged: (tasks) => setState(() {
            selectedTasks = tasks;
            widget.onSelectionChanged(selectedTasks);
          }),
        ),
      ],
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
              normalTitle: "Search tasks",
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
              labelText: "Depth",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                icon: Icon(Icons.clear),
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
              icon: Icon(Icons.expand_less_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWindedView() {
    return InkWell(
      onTap: () {
        setState(() {
          unwinded = true;
        });
      },
      child: Container(
        height: 20.0,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.expand_more_rounded, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}
