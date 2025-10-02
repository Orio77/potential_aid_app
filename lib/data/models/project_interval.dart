import 'package:flutter/material.dart';

class ProjectInterval {
  final int? projectId;
  final String name;
  final int startDay; // 1-based day number
  final int endDay; // 1-based day number
  final double? progress;
  final Color color;

  ProjectInterval({
    this.projectId,
    required this.name,
    required this.startDay,
    required this.endDay,
    required this.color,
    this.progress,
  });

  static List<ProjectInterval> get sampleProjectIntervals => [
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
}
