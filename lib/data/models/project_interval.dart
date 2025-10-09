import 'package:flutter/material.dart';
import 'package:time_machine/time_machine.dart';

class ProjectInterval {
  final int? projectId;
  final String name;
  final LocalDate startDay; // 1-based day number
  final LocalDate endDay; // 1-based day number
  final double? progress;
  final int? categoryId;
  final Color? color;

  ProjectInterval({
    this.projectId,
    required this.name,
    required this.startDay,
    required this.endDay,
    required this.color,
    this.progress,
    this.categoryId,
  });
}
