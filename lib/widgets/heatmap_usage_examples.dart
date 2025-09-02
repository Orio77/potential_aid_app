import 'package:flutter/material.dart';
import 'package:potential_aid_app/widgets/heatmap_widget.dart';

/// Examples of correct heatmap usage in different contexts
class HeatmapUsageExamples {
  /// ✅ CORRECT: Use in project info cards (constrained width)
  static Widget projectInfoExample(int projectId) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Project Activity'),
            const SizedBox(height: 8),
            // Use CompactHeatmapWidget for tight spaces
            CompactHeatmapWidget(
              projectId: projectId,
              months: 3,
              orientation: HeatmapOrientation.horizontal,
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ CORRECT: Use in list items (constrained width)
  static Widget scheduleListExample() {
    return Column(
      children: [
        // Your existing schedule items here
        const ListTile(title: Text('Task 1')),
        const ListTile(title: Text('Task 2')),

        // Add heatmap at the end with proper constraints
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Year Activity'),
                const SizedBox(height: 8),
                // Use ConstrainedHeatmapWidget for list contexts
                ConstrainedHeatmapWidget(
                  year: DateTime.now().year,
                  maxWidth: 350, // Set explicit width limit
                  orientation: HeatmapOrientation.horizontal,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// ✅ CORRECT: Use in full-screen context (unlimited width)
  static Widget fullScreenExample(int projectId) {
    return Scaffold(
      appBar: AppBar(title: const Text('Project Analytics')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Use full HeatmapWidget when you have plenty of space
            HeatmapWidget(
              year: DateTime.now().year,
              projectId: projectId,
              onCellTap: (date, data) {
                // Handle tap
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ CORRECT: Use adaptive widget (automatically chooses)
  static Widget adaptiveExample(int projectId) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Project Progress'),
          const SizedBox(height: 16),
          // AdaptiveHeatmapWidget automatically chooses the right widget
          AdaptiveHeatmapWidget(
            year: DateTime.now().year,
            projectId: projectId,
            onCellTap: (date, data) {
              // Handle tap
            },
          ),
        ],
      ),
    );
  }

  /// ✅ DEMO: Orientation comparison examples
  static Widget orientationComparisonExample(int projectId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Horizontal Orientation (GitHub-style)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          CompactHeatmapWidget(
            projectId: projectId,
            months: 6,
            orientation: HeatmapOrientation.horizontal,
          ),
          const SizedBox(height: 24),
          const Text(
            'Vertical Orientation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          CompactHeatmapWidget(
            projectId: projectId,
            months: 6,
            orientation: HeatmapOrientation.vertical,
          ),
        ],
      ),
    );
  }

  /// ❌ WRONG: Don't use HeatmapWidget directly in constrained contexts
  static Widget wrongUsageExample() {
    return Column(
      children: [
        Card(
          child: HeatmapWidget(
            // This will cause layout errors!
            year: DateTime.now().year,
          ),
        ),
      ],
    );
  }

  /// ✅ CORRECT: Use in dialog (controlled width)
  static void showHeatmapDialog(BuildContext context, int projectId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Project Activity'),
              const SizedBox(height: 16),
              // Use ConstrainedHeatmapWidget in dialogs
              ConstrainedHeatmapWidget(
                year: DateTime.now().year,
                projectId: projectId,
                maxWidth: 350,
                orientation: HeatmapOrientation.horizontal,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
