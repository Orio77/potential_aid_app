import 'package:flutter/material.dart';
import 'package:potential_aid_app/data/database.dart';

/// Fallback slot colours used when a project has no stored colour.
const slotFallbackColors = [
  Color(0xFF1565C0), // blue
  Color(0xFFE65100), // deep orange
  Color(0xFF2E7D32), // green
];

/// Returns a display colour for a slot, preferring the project's own colour.
Color slotColor(int slotIndex, int? projectId, List<ProjectData> projects) {
  if (projectId != null) {
    for (final p in projects) {
      if (p.id == projectId && p.color != null) return Color(p.color!);
    }
  }
  return slotFallbackColors[slotIndex % slotFallbackColors.length];
}

/// Returns a display colour for a project, falling back to its slot's colour.
Color projectColor(
    int projectId, List<ProjectData> projects, List<int?> slots) {
  for (final p in projects) {
    if (p.id == projectId && p.color != null) return Color(p.color!);
  }
  final slotIdx = slots.indexOf(projectId);
  if (slotIdx >= 0) {
    return slotFallbackColors[slotIdx % slotFallbackColors.length];
  }
  return slotFallbackColors[0];
}

/// Finds the first non-deleted, active project with [id] in the list, or null.
ProjectData? findProject(int id, List<ProjectData> projects) {
  for (final p in projects) {
    if (p.id == id && !p.isDeleted) return p;
  }
  return null;
}
