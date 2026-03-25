import 'package:flutter/material.dart';
import 'package:potential_aid_app/schedule/widgets/date_header.dart';
import 'package:potential_aid_app/schedule/widgets/schedule_list.dart';
import 'package:potential_aid_app/schedule/widgets/schedule_progress_bar.dart';

class ScheduleBody extends StatelessWidget {
  const ScheduleBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            DateHeader(),
            SizedBox(height: 8),
            ScheduleProgressBar(),
            SizedBox(height: 16),
            Expanded(child: ScheduleList()),
          ],
        ),
      ),
    );
  }
}
