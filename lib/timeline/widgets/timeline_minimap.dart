import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/timeline/providers/timeline_date_notifier.dart';
import 'package:time_machine/time_machine.dart';

/// Thin year-overview strip. Shows all 12 months; clicking one jumps there.
/// Displayed above the horizontal Gantt on desktop.
class TimelineMinimap extends ConsumerWidget {
  const TimelineMinimap({super.key});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(timelineDateNotifierProvider);
    final year = current.yearOfEra;

    return SizedBox(
      height: 28,
      child: Row(
        children: List.generate(12, (i) {
          final month = i + 1;
          final isSelected = current.monthOfYear == month &&
              current.yearOfEra == year;
          final isToday = LocalDate.today().monthOfYear == month &&
              LocalDate.today().yearOfEra == year;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 3),
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => ref
                    .read(timelineDateNotifierProvider.notifier)
                    .goToMonth(year, month),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : isToday
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.15)
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _months[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
