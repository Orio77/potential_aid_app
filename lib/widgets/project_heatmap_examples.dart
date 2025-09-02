import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/widgets/heatmap_widget.dart';
import 'package:potential_aid_app/providers/task_completion_provider.dart';

/// Example usage of the HeatmapWidget for detailed project analysis
class ProjectHeatmapScreen extends ConsumerWidget {
  final int projectId;
  final String projectName;

  const ProjectHeatmapScreen({
    Key? key,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('$projectName Activity')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Current year heatmap
            Card(
              margin: const EdgeInsets.all(16),
              child: HeatmapWidget(
                year: DateTime.now().year,
                projectId: projectId,
                cellSize: 14.0,
                onCellTap: (date, data) => _showDayDetails(context, date, data),
              ),
            ),

            // Previous year for comparison
            Card(
              margin: const EdgeInsets.all(16),
              child: HeatmapWidget(
                year: DateTime.now().year - 1,
                projectId: projectId,
                cellSize: 12.0,
                onCellTap: (date, data) => _showDayDetails(context, date, data),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayDetails(BuildContext context, DateTime date, HeatmapData? data) {
    if (data == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${date.day}/${date.month}/${date.year}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total completions: ${data.totalCompletions}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (data.taskBreakdown.isNotEmpty) ...[
              const Text('Task breakdown:'),
              const SizedBox(height: 8),
              ...data.taskBreakdown.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Task ${entry.key}'),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${entry.value}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Widget to show heatmap with additional statistics
class ProjectAnalyticsWidget extends ConsumerWidget {
  final int projectId;

  const ProjectAnalyticsWidget({Key? key, required this.projectId})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentYear = DateTime.now().year;
    final heatmapParams = HeatmapParams(
      startDate: DateTime(currentYear, 1, 1),
      endDate: DateTime(currentYear, 12, 31, 23, 59, 59),
      projectId: projectId,
    );

    final heatmapData = ref.watch(heatmapDataProvider(heatmapParams));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Analytics',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            heatmapData.when(
              data: (data) => Column(
                children: [
                  _buildStatistics(context, data),
                  const SizedBox(height: 16),
                  CompactHeatmapWidget(
                    projectId: projectId,
                    months: 6, // Show last 6 months
                    cellSize: 10.0,
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(BuildContext context, List<HeatmapData> data) {
    final totalCompletions = data.fold(
      0,
      (sum, day) => sum + day.totalCompletions,
    );
    final activeDays = data.length;
    final averagePerDay = activeDays > 0
        ? (totalCompletions / activeDays).toStringAsFixed(1)
        : '0';
    final maxDay = data.isEmpty
        ? 0
        : data.map((e) => e.totalCompletions).reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(context, 'Total', totalCompletions.toString()),
        ),
        Expanded(
          child: _buildStatCard(context, 'Active Days', activeDays.toString()),
        ),
        Expanded(child: _buildStatCard(context, 'Avg/Day', averagePerDay)),
        Expanded(child: _buildStatCard(context, 'Best Day', maxDay.toString())),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
