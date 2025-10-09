import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/models/project_interval.dart';
import 'package:potential_aid_app/providers/project_intervals_notifier.dart';
import 'package:potential_aid_app/providers/timeline_date_notifier.dart';
import 'package:potential_aid_app/widgets/timeline/date_card_list.dart';
import 'package:potential_aid_app/widgets/timeline/my_categories_picker_dialog.dart';
import 'package:potential_aid_app/widgets/timeline/project_intervals.dart';
import 'package:potential_aid_app/widgets/timeline/task_cards.dart';
import 'package:potential_aid_app/widgets/timeline/task_depth_navigator.dart';
import 'package:time_machine/time_machine.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  static const double dayCardWidth = 250;
  static const double timelineOuterSpacing = 2;
  late bool showProjects;
  late int depth;
  late ScrollController _horizontalScrollController;
  ProjectCategoryData? selectedCategory;

  @override
  void initState() {
    super.initState();
    showProjects = true;
    depth = 0;
    _horizontalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = ref.watch(timelineDateNotifierProvider);
    final projectsMap = ref.watch(projectIntervalsNotifierProvider);
    final projects = projectsMap.values.toList();

    List<ProjectInterval> filteredProjects = projects
        .where(
          (p) => (selectedCategory == null
              ? true
              : p.categoryId == selectedCategory!.id),
        )
        .toList();

    ref.listen(timelineDateNotifierProvider, (previous, next) {
      if (previous != next) {
        ref
            .read(projectIntervalsNotifierProvider.notifier)
            .loadProjectsForMonth(next);
      }
    });

    if (projects.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(projectIntervalsNotifierProvider.notifier)
            .loadProjectsForMonth(currentMonth);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatMonthYear(currentMonth)),
        centerTitle: true,
        leadingWidth: 100,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              padding: EdgeInsets.zero,
            ),
            Transform.scale(
              scale: 0.6,
              child: Switch(
                value: showProjects,
                onChanged: (value) {
                  setState(() {
                    showProjects = value;
                  });
                },
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ref
                .read(timelineDateNotifierProvider.notifier)
                .goToPreviousMonth(),
            icon: Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: () =>
                ref.read(timelineDateNotifierProvider.notifier).goToToday(),
            icon: Icon(Icons.today),
          ),
          IconButton(
            onPressed: () =>
                ref.read(timelineDateNotifierProvider.notifier).goToNextMonth(),
            icon: Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        height: 40,
        padding: EdgeInsets.zero,
        child: showProjects
            ? IconButton(
                onPressed: () async {
                  final category = await showMyCategoriesPickerDialog(context);
                  setState(() {
                    selectedCategory = category;
                  });
                },
                icon: Icon(
                  selectedCategory == null
                      ? Icons.category
                      : IconData(
                          selectedCategory!.iconCodePoint ?? 0,
                          fontFamily: 'MaterialIcons',
                        ),
                ),
              )
            : TaskDepthNavigator(
                initialDepth: depth,
                onDepthChanged: (value) => setState(() {
                  depth = value;
                }),
              ),
      ),
      body: projects.isEmpty
          ? const CircularProgressIndicator()
          : _buildTimeline(context, filteredProjects),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildTimeline(BuildContext context, List<ProjectInterval> projects) {
    final screenHeight =
        MediaQuery.of(context).size.height - kToolbarHeight - 4;

    final datesInMonth = ref
        .read(timelineDateNotifierProvider.notifier)
        .getAllDaysInMonth();

    final double totalTimelineWidth = dayCardWidth * datesInMonth.length;

    return Padding(
      padding: const EdgeInsets.all(timelineOuterSpacing),
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
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
                  child: showProjects
                      ? ProjectIntervals(
                          projects: projects,
                          dayCardWidth: dayCardWidth,
                          timelineStart: datesInMonth.first,
                          scrollController: _horizontalScrollController,
                        )
                      : TaskCards(
                          key: ValueKey('tasks_depth_$depth'),
                          depth: depth,
                          timelineStart: datesInMonth.first,
                          dayCardWidth: dayCardWidth,
                          scrollController: _horizontalScrollController,
                        ),
                ),
              ),
              DateCardList(dayCardWidth: dayCardWidth, dates: datesInMonth),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMonthYear(LocalDate date) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.monthOfYear - 1]} ${date.yearOfEra}';
  }
}
