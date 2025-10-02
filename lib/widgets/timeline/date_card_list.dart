import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_machine/time_machine.dart';

class DateCardList extends ConsumerWidget {
  final double dayCardWidth;
  final List<LocalDate> dates;

  const DateCardList({
    super.key,
    required this.dayCardWidth,
    required this.dates,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = LocalDate.today();

    return Row(
      children: dates.map((date) {
        final isToday = date == today;
        final isWeekend =
            date.dayOfWeek == DayOfWeek.saturday ||
            date.dayOfWeek == DayOfWeek.sunday;

        return SizedBox(
          width: dayCardWidth,
          child: Card(
            color: isToday
                ? Colors.blue.shade100
                : isWeekend
                ? Colors.grey.shade50
                : null,
            child: Column(
              children: [
                Text(
                  date.dayOfMonth.toString(),
                  style: TextStyle(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: 18,
                  ),
                ),
                Text(
                  _getDayName(date.dayOfWeek.value),
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getDayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return "Monday";
      case 2:
        return "Tuesday";
      case 3:
        return "Wednesday";
      case 4:
        return "Thursday";
      case 5:
        return "Friday";
      case 6:
        return "Saturday";
      case 7:
        return "Sunday";
      default:
        return "Unknown";
    }
  }
}
