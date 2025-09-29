import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter/services.dart';
import 'package:potential_aid_app/widgets/projects/project_task_list_data.dart';
import 'package:potential_aid_app/widgets/projects/search_bar.dart';

class ProjectTaskList extends StatefulWidget {
  final int projectId;
  const ProjectTaskList({super.key, required this.projectId});

  @override
  State<ProjectTaskList> createState() => _ProjectTaskListState();
}

class _ProjectTaskListState extends State<ProjectTaskList> {
  late bool unwinded;
  String? curQuery;
  int? curDepth;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
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
    return Column(children: [
      Container(
        padding: EdgeInsets.all(8.0),
        child: unwinded ? _buildUnwindedView() : _buildWindedView(),
      ),
      ProjectTaskListData(projectId: widget.projectId, query: curQuery, depthLevel: curDepth,),
    ],);
  }

  Widget _buildUnwindedView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SizedBox(
            width: 300,
            child: SearchBar(normalTitle: "Search tasks", onSearchChanged: (query) {
              setState(() {
                curQuery = query;
              });
            }),
          ),
        ),
        const SizedBox(width: 16),
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
        IconButton(onPressed: () {
          setState(() {
            _controller.clear();
            curDepth = null;
            curQuery = null;
            unwinded = !unwinded;
          });
        }, icon: Icon(Icons.expand_less_rounded))
      ],
    );
  }

  Widget _buildWindedView() {
    return GestureDetector(
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