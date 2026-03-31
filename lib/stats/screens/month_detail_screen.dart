import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/stats/providers/stats_provider.dart';
import 'package:time_machine/time_machine.dart';

class MonthDetailScreen extends ConsumerWidget {
  final LocalDate monthYearDate;

  const MonthDetailScreen({super.key, required this.monthYearDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(monthDetailProvider(monthYearDate));
    final month = monthYearDate.monthOfYear.toString().padLeft(2, '0');
    final year = monthYearDate.year;

    return Scaffold(
      appBar: AppBar(
        title: Text('$month $year'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: detail.when(
        data: (d) => _buildBody(context, d),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MonthDetail d) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeadlineRow(context, d),
        const SizedBox(height: 16),
        if (d.timePerProject.isNotEmpty) ...[
          _buildTimePerProjectCard(context, d),
          const SizedBox(height: 16),
        ],
        if (d.tasksPerProject.isNotEmpty) ...[
          _buildTasksPerProjectCard(context, d),
          const SizedBox(height: 16),
        ],
        if (d.dailyBreakdown.isNotEmpty) _buildDailyBreakdownCard(context, d),
      ],
    );
  }

  // ── Headline numbers ───────────────────────────────────────────────────────

  Widget _buildHeadlineRow(BuildContext context, MonthDetail d) {
    final completionPct = (d.completionRate * 100).round();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statTile(
                context,
                label: 'Total time',
                value: _fmtMinutes(d.totalMinutes),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statTile(
                context,
                label: 'Completion',
                value: d.plannedMinutes > 0 ? '$completionPct%' : '—',
                sub: d.plannedMinutes > 0
                    ? 'of ${_fmtMinutes(d.plannedMinutes)} planned'
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statTile(
                context,
                label: 'Active days',
                value: '${d.activeDays}',
                sub: d.activeDays > 0
                    ? 'avg ${_fmtMinutes(d.avgMinutesPerActiveDay)}/day'
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statTile(
                context,
                label: 'Longest session',
                value: d.longestSessionMinutes > 0
                    ? _fmtMinutes(d.longestSessionMinutes)
                    : '—',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statTile(
    BuildContext context, {
    required String label,
    required String value,
    String? sub,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(sub, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  // ── Time per project ───────────────────────────────────────────────────────

  Widget _buildTimePerProjectCard(BuildContext context, MonthDetail d) {
    final maxMinutes = d.timePerProject.first.minutes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time per project',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...d.timePerProject.map((p) {
              final fraction = maxMinutes > 0 ? p.minutes / maxMinutes : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            p.projectName,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _fmtMinutes(p.minutes),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Tasks per project ──────────────────────────────────────────────────────

  Widget _buildTasksPerProjectCard(BuildContext context, MonthDetail d) {
    final maxTasks = d.tasksPerProject.first.taskCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tasks completed',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...d.tasksPerProject.map((p) {
              final fraction = maxTasks > 0 ? p.taskCount / maxTasks : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            p.projectName,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${p.taskCount} ${p.taskCount == 1 ? "task" : "tasks"}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Daily breakdown ────────────────────────────────────────────────────────

  Widget _buildDailyBreakdownCard(BuildContext context, MonthDetail d) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily breakdown',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {
                0: FixedColumnWidth(44),
                1: FlexColumnWidth(),
                2: FixedColumnWidth(60),
              },
              children: [
                TableRow(
                  children: [
                    _tableHeader(context, 'Day'),
                    _tableHeader(context, 'Time'),
                    _tableHeader(context, 'Tasks', align: TextAlign.right),
                  ],
                ),
                ...d.dailyBreakdown.map(
                  (b) => TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${b.day}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          b.minutes > 0 ? _fmtMinutes(b.minutes) : '—',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          b.tasksCompleted > 0 ? '${b.tasksCompleted}' : '—',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(BuildContext context, String text,
      {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(fontWeight: FontWeight.bold),
        textAlign: align,
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fmtMinutes(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }
}
