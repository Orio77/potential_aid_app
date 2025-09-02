import 'package:flutter/material.dart';

// TODO
class ScheduleProgressBar extends StatelessWidget {
  const ScheduleProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: LinearProgressIndicator(value: 0.34),
    );
  }
}
