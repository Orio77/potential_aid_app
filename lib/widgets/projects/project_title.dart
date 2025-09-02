import 'package:flutter/widgets.dart';

class ProjectTitle extends StatelessWidget {
  final String title;
  const ProjectTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
    );
  }
}
