import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_machine/time_machine.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';

class DateHeader extends ConsumerWidget {
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

    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () =>
                ref.read(dateNotifierProvider.notifier).goToPreviousDay(),
            icon: Icon(Icons.arrow_back),
          ),
          GestureDetector(
            onLongPress: pickDate,
            child: Text(
              '${currentDate.dayOfMonth} / ${currentDate.monthOfYear} / ${currentDate.year}',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          IconButton(
            onPressed: () =>
                ref.read(dateNotifierProvider.notifier).goToNextDay(),
            icon: Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}
