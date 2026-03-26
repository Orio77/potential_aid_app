import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/models/project_interval.dart';
import 'package:potential_aid_app/providers/project_intervals_notifier.dart';
import 'package:potential_aid_app/providers/task_cards_notifier.dart';
import 'package:potential_aid_app/providers/timeline_date_notifier.dart';
import 'package:potential_aid_app/projects/widgets/select_project_dialog.dart';
import 'package:potential_aid_app/timeline/widgets/date_card_list.dart';
import 'package:potential_aid_app/timeline/widgets/my_categories_picker_dialog.dart';
import 'package:potential_aid_app/timeline/widgets/project_intervals.dart';
import 'package:potential_aid_app/timeline/widgets/task_cards.dart';
import 'package:potential_aid_app/timeline/widgets/task_depth_navigator.dart';
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
  ProjectData? selectedProject;

  @override
  void initState() {
    super.initState();
    showProjects = true;
    depth = 0;
    _horizontalScrollController = ScrollController(
      initialScrollOffset: dayCardWidth * (DateTime.now().day - 1),
    );
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

    List<ProjectInterval> filteredProjects;

    if (selectedProject != null) {
      filteredProjects = ref
          .read(projectIntervalsNotifierProvider.notifier)
          .mapProjectsToIntervals([selectedProject!])
          .toList();
    } else {
      // Apply category filter if no specific project is selected
      filteredProjects = projects
          .where(
            (p) => (selectedCategory == null
                ? true
                : p.categoryId == selectedCategory!.id),
          )
          .toList();
    }

    ref.listen(timelineDateNotifierProvider, (previous, next) {
      if (previous != next) {
        ref
            .read(projectIntervalsNotifierProvider.notifier)
            .loadProjectsForMonth(next);

        // Also reload tasks for the new month if we're showing tasks
        if (!showProjects) {
          ref
              .read(taskCardsNotifierProvider(depth).notifier)
              .loadTasksForMonth(
                monthDate: next,
                depth: depth,
                categoryId: selectedCategory?.id,
                projectId: selectedProject?.id,
              );
        }
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

                  // Reload tasks when switching to task view with category filter
                  if (!value && selectedCategory != null) {
                    final currentMonth = ref.read(timelineDateNotifierProvider);
                    ref
                        .read(taskCardsNotifierProvider(depth).notifier)
                        .loadTasksForMonth(
                          monthDate: currentMonth,
                          depth: depth,
                          categoryId: selectedCategory?.id,
                          projectId: selectedProject?.id,
                        );
                  }
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () async {
                final category = await showMyCategoriesPickerDialog(context);
                final previousCategory = selectedCategory;
                setState(() {
                  selectedCategory = category;
                  // Clear project selection when changing category to avoid conflicts
                  if (category?.id != previousCategory?.id) {
                    selectedProject = null;
                  }
                });

                // Reload tasks if we're showing tasks and category changed
                if (!showProjects && category?.id != previousCategory?.id) {
                  final currentMonth = ref.read(timelineDateNotifierProvider);
                  ref
                      .read(taskCardsNotifierProvider(depth).notifier)
                      .loadTasksForMonth(
                        monthDate: currentMonth,
                        depth: depth,
                        categoryId: category?.id,
                        projectId:
                            null, // Clear project filter when category changes
                      );
                }
              },
              icon: Icon(
                selectedCategory == null
                    ? Icons.category
                    : IconData(
                        selectedCategory!.iconCodePoint ?? 0,
                        fontFamily: 'MaterialIcons',
                      ),
              ),
            ),
            if (!showProjects) ...[
              TaskDepthNavigator(
                initialDepth: depth,
                onDepthChanged: (value) => setState(() {
                  depth = value;
                }),
              ),
            ],
            IconButton(
              onPressed: () async {
                final ProjectData? projectData = await showSelectProjectDialog(
                  context,
                );
                final previousProject = selectedProject;
                setState(() {
                  selectedProject = projectData;
                });

                // Reload tasks if we're showing tasks and project changed
                if (!showProjects && projectData?.id != previousProject?.id) {
                  final currentMonth = ref.read(timelineDateNotifierProvider);
                  ref
                      .read(taskCardsNotifierProvider(depth).notifier)
                      .loadTasksForMonth(
                        monthDate: currentMonth,
                        depth: depth,
                        categoryId: selectedCategory?.id,
                        projectId: projectData?.id,
                      );
                }
              },
              icon: Icon(
                selectedProject != null
                    ? Icons.folder_special_rounded
                    : Icons.folder_copy_outlined,
              ),
            ),
          ],
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
                          categoryId: selectedCategory?.id,
                          timelineStart: datesInMonth.first,
                          dayCardWidth: dayCardWidth,
                          scrollController: _horizontalScrollController,
                          projectId: selectedProject?.id,
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
