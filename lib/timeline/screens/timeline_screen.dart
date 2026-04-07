import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/models/project_interval.dart';
import 'package:potential_aid_app/providers/project_intervals_notifier.dart';
import 'package:potential_aid_app/providers/settings_notifier.dart';
import 'package:potential_aid_app/timeline/providers/task_cards_notifier.dart';
import 'package:potential_aid_app/timeline/providers/timeline_date_notifier.dart';
import 'package:potential_aid_app/timeline/providers/timeline_density_provider.dart';
import 'package:potential_aid_app/timeline/providers/timeline_range_provider.dart';
import 'package:potential_aid_app/projects/widgets/select_project_dialog.dart';
import 'package:potential_aid_app/timeline/widgets/date_card_list.dart';
import 'package:potential_aid_app/timeline/widgets/mobile_project_list.dart';
import 'package:potential_aid_app/timeline/widgets/mobile_task_agenda.dart';
import 'package:potential_aid_app/timeline/widgets/my_categories_picker_dialog.dart';
import 'package:potential_aid_app/timeline/widgets/project_intervals.dart';
import 'package:potential_aid_app/timeline/widgets/task_cards.dart';
import 'package:potential_aid_app/timeline/widgets/task_depth_navigator.dart';
import 'package:potential_aid_app/timeline/widgets/density_toggle.dart';
import 'package:potential_aid_app/timeline/widgets/range_toggle.dart';
import 'package:potential_aid_app/timeline/widgets/task_swim_lanes.dart';
import 'package:potential_aid_app/timeline/widgets/timeline_minimap.dart';
import 'package:time_machine/time_machine.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  static const double _defaultDayCardWidth = 250.0; // matches normal density
  static const double timelineOuterSpacing = 2;
  late bool showProjects;
  late int depth;
  late ScrollController _horizontalScrollController;
  ProjectCategoryData? selectedCategory;
  ProjectData? selectedProject;
  bool _showOnlyUncompleted = true;
  bool _timelineDefaultsResolved = false;
  bool _swimLaneMode = false;

  @override
  void initState() {
    super.initState();
    showProjects = true;
    depth = 0;
    _horizontalScrollController = ScrollController(
      initialScrollOffset: _defaultDayCardWidth * (DateTime.now().day - 1),
    );
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveTimelineDefaults();
    });
  }

  Future<void> _resolveTimelineDefaults() async {
    final defaults = await ref
        .read(settingsNotifierProvider.notifier)
        .resolveTimelineDefaults();
    if (!mounted) return;
    setState(() {
      showProjects = defaults.showProjects;
      selectedProject = defaults.project;
      selectedCategory = defaults.category;
      _showOnlyUncompleted = defaults.showOnlyUncompleted;
      _timelineDefaultsResolved = true;
    });

    final currentMonth = ref.read(timelineDateNotifierProvider);
    await ref
        .read(projectIntervalsNotifierProvider.notifier)
        .loadProjectsForMonth(currentMonth);
    if (!mounted) return;
    if (!defaults.showProjects) {
      await ref
          .read(taskCardsNotifierProvider(depth).notifier)
          .loadTasksForMonth(
            monthDate: currentMonth,
            depth: depth,
            categoryId: defaults.category?.id,
            projectId: defaults.project?.id,
            showOnlyUncompleted: defaults.showOnlyUncompleted,
          );
    }
  }

  Future<void> _onTimelineMenuSelected(int value, BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    if (value == 0) {
      await ref
          .read(settingsNotifierProvider.notifier)
          .saveCurrentTimelineAsDefault(
            project: selectedProject,
            category: selectedCategory,
            showProjects: showProjects,
            showOnlyUncompleted: _showOnlyUncompleted,
          );
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Timeline default saved')),
        );
      }
    } else if (value == 1) {
      await ref.read(settingsNotifierProvider.notifier).clearTimelineDefaults();
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Timeline default cleared')),
        );
      }
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _horizontalScrollController.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!mounted) return false;
    if (ModalRoute.of(context)?.isCurrent != true) return false;
    if (event is! KeyDownEvent) return false;
    if (!HardwareKeyboard.instance.isControlPressed) return false;

    final range = ref.read(timelineRangeProvider);
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      ref
          .read(timelineDateNotifierProvider.notifier)
          .goToPreviousRange(range);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      ref.read(timelineDateNotifierProvider.notifier).goToNextRange(range);
      return true;
    }
    if (key == LogicalKeyboardKey.keyT) {
      ref.read(timelineDateNotifierProvider.notifier).goToToday();
      return true;
    }
    return false;
  }

  void _onModeSwitch(bool value) {
    setState(() => showProjects = value);
    if (!value) {
      final currentMonth = ref.read(timelineDateNotifierProvider);
      ref.read(taskCardsNotifierProvider(depth).notifier).loadTasksForMonth(
            monthDate: currentMonth,
            depth: depth,
            categoryId: selectedCategory?.id,
            projectId: selectedProject?.id,
            showOnlyUncompleted: _showOnlyUncompleted,
          );
    }
  }

  void _scrollToToday(double dayCardWidth) {
    if (!_horizontalScrollController.hasClients) return;
    final offset = dayCardWidth * (DateTime.now().day - 1);
    _horizontalScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = ref.watch(timelineDateNotifierProvider);
    final range = ref.watch(timelineRangeProvider);
    final density = ref.watch(timelineDensityProvider);
    final dayCardWidth = density.cardWidth;

    // Scroll to today when density changes
    ref.listen(timelineDensityProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToToday(dayCardWidth),
      );
    });

    if (!_timelineDefaultsResolved) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_formatRangeTitle(currentMonth, range)),
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
        backgroundColor: Colors.white,
      );
    }

    final projectsMap = ref.watch(projectIntervalsNotifierProvider);
    final appSettings = ref.watch(settingsNotifierProvider);
    final projects = projectsMap.values.toList();

    List<ProjectInterval> filteredProjects;

    if (selectedProject != null) {
      filteredProjects = ref
          .read(projectIntervalsNotifierProvider.notifier)
          .mapProjectsToIntervals([selectedProject!])
          .toList();
    } else {
      filteredProjects = projects
          .where(
            (p) => (selectedCategory == null
                ? true
                : p.categoryId == selectedCategory!.id),
          )
          .toList();
    }

    if (_showOnlyUncompleted) {
      filteredProjects =
          filteredProjects.where((p) => (p.progress ?? 0) < 1.0).toList();
    }

    ref.listen(timelineDateNotifierProvider, (previous, next) {
      if (previous != next) {
        ref
            .read(projectIntervalsNotifierProvider.notifier)
            .loadProjectsForMonth(next);

        if (!showProjects) {
          ref
              .read(taskCardsNotifierProvider(depth).notifier)
              .loadTasksForMonth(
                monthDate: next,
                depth: depth,
                categoryId: selectedCategory?.id,
                projectId: selectedProject?.id,
                showOnlyUncompleted: _showOnlyUncompleted,
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

    final isNarrow = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatRangeTitle(currentMonth, range, compact: isNarrow)),
        centerTitle: true,
        // Wide: back + mode switch in leading.
        // Narrow: back button only; mode switch moves to bottom bar.
        leadingWidth: isNarrow ? kToolbarHeight : 100,
        leading: isNarrow
            ? IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : Row(
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
                      onChanged: (value) => _onModeSwitch(value),
                    ),
                  ),
                ],
              ),
        actions: [
          // Density + Range toggles only on wide (desktop timeline) screens.
          if (!isNarrow) ...[
            DensityToggle(
              current: density,
              onChanged: (d) =>
                  ref.read(timelineDensityProvider.notifier).state = d,
            ),
            const SizedBox(width: 4),
            RangeToggle(
              current: range,
              onChanged: (r) {
                ref.read(timelineRangeProvider.notifier).state = r;
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToToday(dayCardWidth),
                );
              },
            ),
            const SizedBox(width: 4),
          ],
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _onTimelineMenuSelected(value, context),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 0,
                child: Text('Use current view as default'),
              ),
              PopupMenuItem(
                value: 1,
                enabled: appSettings.hasTimelineCustomization,
                child: const Text('Clear saved timeline default'),
              ),
            ],
          ),
          IconButton(
            onPressed: () => ref
                .read(timelineDateNotifierProvider.notifier)
                .goToPreviousRange(range),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: () {
              ref.read(timelineDateNotifierProvider.notifier).goToToday();
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _scrollToToday(dayCardWidth),
              );
            },
            icon: const Icon(Icons.today),
          ),
          IconButton(
            onPressed: () => ref
                .read(timelineDateNotifierProvider.notifier)
                .goToNextRange(range),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        height: 40,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mode switch visible in bottom bar only on narrow screens.
            if (isNarrow)
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: showProjects,
                  onChanged: (value) => _onModeSwitch(value),
                ),
              ),
            IconButton(
              onPressed: () async {
                final category = await showMyCategoriesPickerDialog(context);
                final previousCategory = selectedCategory;
                setState(() {
                  selectedCategory = category;
                  if (category?.id != previousCategory?.id) {
                    selectedProject = null;
                  }
                });

                if (!showProjects && category?.id != previousCategory?.id) {
                  final currentMonth = ref.read(timelineDateNotifierProvider);
                  ref
                      .read(taskCardsNotifierProvider(depth).notifier)
                      .loadTasksForMonth(
                        monthDate: currentMonth,
                        depth: depth,
                        categoryId: category?.id,
                        projectId: null,
                        showOnlyUncompleted: _showOnlyUncompleted,
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
            IconButton(
              onPressed: () => setState(
                () => _showOnlyUncompleted = !_showOnlyUncompleted,
              ),
              icon: Icon(
                _showOnlyUncompleted
                    ? Icons.check_circle_outline
                    : Icons.checklist,
              ),
            ),
            if (!showProjects) ...[
              TaskDepthNavigator(
                initialDepth: depth,
                onDepthChanged: (value) => setState(() {
                  depth = value;
                }),
              ),
              // Swim-lane toggle only makes sense on desktop timeline.
              if (!isNarrow)
                IconButton(
                  onPressed: () =>
                      setState(() => _swimLaneMode = !_swimLaneMode),
                  icon: Icon(
                    _swimLaneMode ? Icons.view_week : Icons.table_rows,
                    size: 20,
                  ),
                  tooltip: _swimLaneMode ? 'Column view' : 'Swim-lane view',
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

                if (!showProjects && projectData?.id != previousProject?.id) {
                  final currentMonth = ref.read(timelineDateNotifierProvider);
                  ref
                      .read(taskCardsNotifierProvider(depth).notifier)
                      .loadTasksForMonth(
                        monthDate: currentMonth,
                        depth: depth,
                        categoryId: selectedCategory?.id,
                        projectId: projectData?.id,
                        showOnlyUncompleted: _showOnlyUncompleted,
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
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return showProjects
                      ? MobileProjectList(projects: filteredProjects)
                      : MobileTaskAgenda(depth: depth);
                }
                return _buildDesktopTimeline(
                  context,
                  filteredProjects,
                  dayCardWidth,
                  range,
                );
              },
            ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildDesktopTimeline(
    BuildContext context,
    List<ProjectInterval> projects,
    double dayCardWidth,
    TimelineRange range,
  ) {
    final screenHeight =
        MediaQuery.of(context).size.height - kToolbarHeight - 4;

    final datesInRange = ref
        .read(timelineDateNotifierProvider.notifier)
        .getDaysInRange(range);

    final double totalTimelineWidth = dayCardWidth * datesInRange.length;

    // Today line position
    final today = LocalDate.today();
    final todayIndex = datesInRange.indexWhere((d) => d == today);

    return Column(
      children: [
        // Mini-map scrubber (only in month/quarter range)
        if (range != TimelineRange.week) const TimelineMinimap(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(timelineOuterSpacing),
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: totalTimelineWidth,
                height: range == TimelineRange.week
                    ? screenHeight
                    : screenHeight - 28, // subtract minimap height
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            physics: const BouncingScrollPhysics(),
                            reverse: true,
                            child: showProjects
                                ? ProjectIntervals(
                                    projects: projects,
                                    dayCardWidth: dayCardWidth,
                                    timelineStart: datesInRange.first,
                                    timelineEnd: datesInRange.last,
                                    scrollController:
                                        _horizontalScrollController,
                                  )
                                : _swimLaneMode
                                    ? TaskSwimLanes(
                                        key: ValueKey(
                                          'swimlanes_depth_$depth',
                                        ),
                                        depth: depth,
                                        dayCardWidth: dayCardWidth,
                                        timelineStart: datesInRange.first,
                                        datesInRange: datesInRange,
                                      )
                                    : TaskCards(
                                        key: ValueKey('tasks_depth_$depth'),
                                        depth: depth,
                                        categoryId: selectedCategory?.id,
                                        timelineStart: datesInRange.first,
                                        dayCardWidth: dayCardWidth,
                                        scrollController:
                                            _horizontalScrollController,
                                        projectId: selectedProject?.id,
                                        showOnlyUncompleted:
                                            _showOnlyUncompleted,
                                      ),
                          ),
                        ),
                        DateCardList(
                          dayCardWidth: dayCardWidth,
                          dates: datesInRange,
                        ),
                      ],
                    ),
                    // Today vertical indicator line
                    if (todayIndex >= 0)
                      Positioned(
                        left: todayIndex * dayCardWidth +
                            dayCardWidth / 2 -
                            1,
                        top: 0,
                        bottom: 0,
                        width: 2,
                        child: IgnorePointer(
                          child: Container(
                            color: Colors.blue.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatRangeTitle(LocalDate date, TimelineRange range,
      {bool compact = false}) {
    const full = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const abbr = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final m = compact ? abbr : full;

    switch (range) {
      case TimelineRange.week:
        final end = date.addDays(6);
        return '${date.dayOfMonth} ${abbr[date.monthOfYear - 1]}'
            ' – ${end.dayOfMonth} ${abbr[end.monthOfYear - 1]} ${end.yearOfEra}';
      case TimelineRange.month:
        return '${m[date.monthOfYear - 1]} ${date.yearOfEra}';
      case TimelineRange.quarter:
        final qEndMonth = ((date.monthOfYear - 1 + 2) % 12) + 1;
        return '${abbr[date.monthOfYear - 1]} – ${abbr[qEndMonth - 1]} ${date.yearOfEra}';
    }
  }
}

