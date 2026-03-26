import 'package:flutter/material.dart';

class TaskDepthNavigator extends StatefulWidget {
  final int initialDepth;
  final ValueChanged<int>? onDepthChanged;

  const TaskDepthNavigator({
    super.key,
    required this.initialDepth,
    this.onDepthChanged,
  });

  @override
  State<TaskDepthNavigator> createState() => _TaskDepthNavigatorState();
}

class _TaskDepthNavigatorState extends State<TaskDepthNavigator> {
  late int depth;
  final double iconSize = 20.0;

  @override
  void initState() {
    super.initState();
    depth = widget.initialDepth;
  }

  void _updateDepth(int newDepth) {
    setState(() {
      depth = newDepth;
    });
    widget.onDepthChanged?.call(newDepth);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_upward),
              onPressed: () => _updateDepth(depth + 1),
              iconSize: iconSize,
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_downward),
              onPressed: () => _updateDepth((depth > 0) ? depth - 1 : 0),
              iconSize: iconSize,
            ),
          ],
        ),
        const SizedBox(width: 12),
        Text(depth.toString(), style: TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => _updateDepth(0),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}
