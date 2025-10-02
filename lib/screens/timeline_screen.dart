import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/models/project_interval.dart';
import 'package:potential_aid_app/widgets/timeline/date_card_list.dart';
import 'package:potential_aid_app/widgets/timeline/project_intervals.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  static const double dayCardWidth = 250;
  static const double dayCardHeight = 300.0;
  static const double timelineOuterSpacing = 2;

  late int daysOfMonth;

  @override
  void initState() {
    super.initState();
    daysOfMonth = 30;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight =
        MediaQuery.of(context).size.height - kToolbarHeight - 4;
    final double totalTimelineWidth = dayCardWidth * daysOfMonth;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Timeline For _Month"),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(timelineOuterSpacing),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: BouncingScrollPhysics(),
          child: SizedBox(
            width: totalTimelineWidth,
            height: screenHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    physics: BouncingScrollPhysics(),
                    reverse: true,
                    child: ProjectIntervals(
                      projects: ProjectInterval.sampleProjectIntervals,
                      dayCardHeight: dayCardHeight,
                      dayCardWidth: dayCardWidth,
                    ),
                  ),
                ),
                DateCardList(
                  dayCardWidth: dayCardWidth,
                  dayCardHeight: dayCardHeight,
                  daysOfMonth: daysOfMonth,
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
