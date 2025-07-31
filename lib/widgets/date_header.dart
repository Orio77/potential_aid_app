import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_machine/time_machine.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';

class DateHeader extends ConsumerWidget {
  const DateHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDate = ref.watch(dateNotifierProvider);

    Future<void> pickDate() async {
      final DateTime? selected = await showDatePicker(
        context: context,
        initialDate: currentDate.toDateTimeUnspecified(),
        firstDate: DateTime(2022),
        lastDate: currentDate.toDateTimeUnspecified().add(Duration(days: 7)),
      );

      if (selected != null) {
        ref
            .read(dateNotifierProvider.notifier)
            .goToDay(LocalDate.dateTime(selected));
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () =>
              ref.read(dateNotifierProvider.notifier).goToPreviousDay(),
          icon: Icon(Icons.arrow_back),
        ),
        GestureDetector(
          onLongPress: pickDate,
          child: Card(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Text(
                '${currentDate.dayOfMonth} / ${currentDate.monthOfYear} / ${currentDate.year}',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () =>
              ref.read(dateNotifierProvider.notifier).goToNextDay(),
          icon: Icon(Icons.arrow_forward),
        ),
      ],
    );
  }
}
