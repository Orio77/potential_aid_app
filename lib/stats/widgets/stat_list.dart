import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/stats/providers/stats_provider.dart';
import 'package:potential_aid_app/stats/screens/month_detail_screen.dart';
import 'package:potential_aid_app/stats/widgets/barmap.dart';
import 'package:time_machine/time_machine.dart';

// [E] How many months of bar charts are shown; incremented by "Show more".
final _monthsToShowProvider = StateProvider<int>((ref) => 4);

class StatList extends ConsumerWidget {
  const StatList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthsToShow = ref.watch(_monthsToShowProvider);
    final months = List.generate(
      monthsToShow,
      (i) => LocalDate.today().subtractMonths(i),
    );

    // Total list items: header + N month cards + day-of-week card + load-more
    final itemCount = 1 + months.length + 1 + 1;

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == 0) return _buildSummaryHeader(context, ref);
        if (index <= months.length) {
          return _buildBarMapCard(context, ref, months[index - 1]);
        }
        if (index == months.length + 1) return _buildDayOfWeekCard(ref);
        return _buildLoadMoreButton(ref);
      },
    );
  }

  // ── [A] + [B] Summary header ────────────────────────────────────────────────

  Widget _buildSummaryHeader(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(currentStreakProvider);
    final weekSummary = ref.watch(weekSummaryProvider);

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStreakCard(context, streak)),
            const SizedBox(width: 12),
            Expanded(child: _buildWeekCard(context, weekSummary)),
          ],
        ),
      ],
    );
  }

  /// [A] Streak card.
  Widget _buildStreakCard(BuildContext context, AsyncValue<int> streak) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: streak.when(
          data: (days) => Column(
            children: [
              Text(
                '$days',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: days > 0
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                days == 1 ? 'day streak' : 'day streak',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          loading: () => const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  /// [B] Weekly planned vs completed block time.
  Widget _buildWeekCard(BuildContext context, AsyncValue<WeekSummary> weekSummary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: weekSummary.when(
          data: (summary) {
            if (summary.plannedMinutes == 0 && summary.completedMinutes == 0) {
              return Column(
                children: [
                  Text(
                    'This week',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No blocks planned',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }
            final progress = summary.plannedMinutes > 0
                ? (summary.completedMinutes / summary.plannedMinutes).clamp(
                    0.0,
                    1.0,
                  )
                : 0.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This week',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMinutes(summary.completedMinutes),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (summary.plannedMinutes > 0)
                  Text(
                    'of ${_formatMinutes(summary.plannedMinutes)} planned',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 8),
                if (summary.plannedMinutes > 0)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                    ),
                  ),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  // ── Monthly bar card ─────────────────────────────────────────────────────────

  Widget _buildBarMapCard(BuildContext context, WidgetRef ref, LocalDate monthYearDate) {
    final blockCompletions = ref.watch(
      blockCompletionMonthlyNotifier(monthYearDate),
    );

    return blockCompletions.when(
      data: (data) {
        if (data.isEmpty) return const SizedBox.shrink();

        // [H] Best day callout from already-loaded data.
        final bestDay = _bestDay(data, monthYearDate);

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      MonthDetailScreen(monthYearDate: monthYearDate),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${monthYearDate.monthOfYear.toString().padLeft(2, '0')} ${monthYearDate.year}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (bestDay != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          '· best: day $bestDay',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: BarMap(monthYearDate: monthYearDate),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, trace) => Text("Error: $error"),
    );
  }

  // ── [F] Day-of-week breakdown card ──────────────────────────────────────────

  Widget _buildDayOfWeekCard(WidgetRef ref) {
    final dowStats = ref.watch(dayOfWeekStatsProvider);

    return dowStats.when(
      data: (byDay) {
        if (byDay.every((m) => m == 0)) return const SizedBox.shrink();

        final maxMinutes = byDay.reduce(max);
        const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'By day of week (last 90 days)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...List.generate(7, (i) {
                  final minutes = byDay[i];
                  final fraction =
                      maxMinutes > 0 ? minutes / maxMinutes : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            dayLabels[i],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: fraction,
                              minHeight: 14,
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          child: Text(
                            _formatMinutes(minutes),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.right,
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
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  // ── [E] Load more button ─────────────────────────────────────────────────────

  Widget _buildLoadMoreButton(WidgetRef ref) {
    return Center(
      child: TextButton.icon(
        icon: const Icon(Icons.expand_more),
        label: const Text('Show more months'),
        onPressed: () {
          ref.read(_monthsToShowProvider.notifier).state += 4;
        },
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// [H] Returns the day-of-month with the highest total block completion minutes.
  int? _bestDay(List<BlockCompletionData> completions, LocalDate month) {
    final dailyTotals = <int, int>{};
    for (final c in completions) {
      final day = c.completedAt.day;
      if (c.completedAt.month == month.monthOfYear &&
          c.completedAt.year == month.yearOfEra) {
        dailyTotals[day] = (dailyTotals[day] ?? 0) + c.count;
      }
    }
    if (dailyTotals.isEmpty) return null;
    return dailyTotals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  String _formatMinutes(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }
}
