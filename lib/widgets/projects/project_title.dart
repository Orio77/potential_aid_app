import 'package:flutter/widgets.dart';

class ProjectTitle extends StatelessWidget {
  final String title;
  const ProjectTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double fontSize;
        if (constraints.maxWidth < 200) {
          fontSize = 18;
        } else if (constraints.maxWidth < 300) {
          fontSize = 22;
        } else {
          fontSize = 26;
        }

        return Text(
          title,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
