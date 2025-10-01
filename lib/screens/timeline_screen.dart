import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Sample project data structure
class ProjectInterval {
  final String name;
  final int startDay; // 1-based day number
  final int endDay; // 1-based day number
  final Color color;

  ProjectInterval({
    required this.name,
    required this.startDay,
    required this.endDay,
    required this.color,
  });
}

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  // Sample project data
  final List<ProjectInterval> projects = [
    ProjectInterval(
      name: "Website Redesign",
      startDay: 2,
      endDay: 8,
      color: Colors.blue.shade300,
    ),
    ProjectInterval(
      name: "Mobile App",
      startDay: 5,
      endDay: 15,
      color: Colors.green.shade300,
    ),
    ProjectInterval(
      name: "Marketing Campaign",
      startDay: 10,
      endDay: 20,
      color: Colors.orange.shade300,
    ),
    ProjectInterval(
      name: "Database Migration",
      startDay: 3,
      endDay: 7,
      color: Colors.purple.shade300,
    ),
    ProjectInterval(
      name: "User Testing",
      startDay: 18,
      endDay: 25,
      color: Colors.red.shade300,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight =
        MediaQuery.of(context).size.height - kToolbarHeight - 32;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Timeline For _Month"),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: screenHeight,
          child: Stack(
            children: [
              _buildDateCards(screenHeight),
              _buildProjectIntervals(screenHeight),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildDateCards(double screenHeight) {
    const dayCardHeight = 300.0;
    const spacing = 16.0;
    final projectsHeight = screenHeight - dayCardHeight - spacing;

    return Row(
      children: List.generate(30, (index) {
        return Container(
          width: 250,
          margin: const EdgeInsets.only(right: 16),
          child: Column(
            children: [
              _buildProjectCards(projectsHeight),
              const SizedBox(height: spacing),
              SizedBox(
                height: dayCardHeight,
                width: double.infinity,
                child: Card(child: Center(child: Text("Day ${index + 1}"))),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProjectCards(double height) {
    return SizedBox(
      height: height,
      child: Card(
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: Random().nextInt(10) + 1,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Project $index"),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProjectIntervals(double screenHeight) {
    const dayCardHeight = 300.0;
    const spacing = 16.0;
    final projectsHeight = screenHeight - dayCardHeight - spacing;
    const dayWidth = 250.0;
    const dayMargin = 16.0;
    const projectBarHeight = 40.0;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: projectsHeight,
        child: Stack(
          children: projects.asMap().entries.map((entry) {
            final index = entry.key;
            final project = entry.value;

            // Calculate position and width
            final startX = (project.startDay - 1) * (dayWidth + dayMargin);
            final endX = project.endDay * (dayWidth + dayMargin) - dayMargin;
            final width = endX - startX;
            final topOffset = index * (projectBarHeight + 8.0) + 16.0;

            return Positioned(
              left: startX,
              top: topOffset,
              child: Container(
                width: width,
                height: projectBarHeight,
                decoration: BoxDecoration(
                  color: project.color,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "Day ${project.startDay}-${project.endDay}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
