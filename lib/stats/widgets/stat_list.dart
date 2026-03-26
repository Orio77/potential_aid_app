import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/stats_provider.dart';
import 'package:potential_aid_app/stats/widgets/barmap.dart';
import 'package:time_machine/time_machine.dart';

class StatList extends ConsumerWidget {
  const StatList({super.key});

  static const int _monthsToShow = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final months = List.generate(
      _monthsToShow,
      (i) => LocalDate.today().subtractMonths(i),
    );

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: months.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildBarMapCard(ref, months[index]),
    );
  }

  Widget _buildBarMapCard(WidgetRef ref, LocalDate monthYearDate) {
    final completions = ref.watch(
      taskCompletionMonthlyNotifier(
        TaskCompletionParams(monthYearDate: monthYearDate),
      ),
    );

    return completions.when(
      data: (data) {
        if (data.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "${monthYearDate.monthOfYear.toString().padLeft(2, '0')} ${monthYearDate.year}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: BarMap(monthYearDate: monthYearDate),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, trace) => Text("Error: $error"),
    );
  }
}
