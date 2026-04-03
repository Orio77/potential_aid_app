import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/timeline/providers/timeline_range_provider.dart';
import 'package:time_machine/time_machine.dart';

class TimelineDateNotifier extends StateNotifier<LocalDate> {
  TimelineDateNotifier()
    : super(
        LocalDate(
          LocalDate.today().yearOfEra,
          LocalDate.today().monthOfYear,
          1,
        ),
      );

  void goToMonth(int year, int month) {
    state = LocalDate(year, month, 1);
  }

  void goToNextMonth() {
    state = state.addMonths(1);
  }

  void goToPreviousMonth() {
    state = state.subtractMonths(1);
  }

  void goToToday() {
    state = LocalDate.today();
  }

  int getDaysInCurrentMonth() {
    return state.calendar.getDaysInMonth(state.yearOfEra, state.monthOfYear);
  }

  LocalDate getMonthStart() {
    return LocalDate(state.yearOfEra, state.monthOfYear, 1);
  }

  LocalDate getMonthEnd() {
    return getMonthStart().addMonths(1).subtractDays(1);
  }

  List<LocalDate> getAllDaysInMonth() {
    final start = getMonthStart();
    final end = getMonthEnd();
    final days = <LocalDate>[];

    var current = start;
    while (current <= end) {
      days.add(current);
      current = current.addDays(1);
    }
    return days;
  }

  List<LocalDate> getDaysInRange(TimelineRange range) {
    switch (range) {
      case TimelineRange.week:
        return List.generate(7, (i) => state.addDays(i));
      case TimelineRange.month:
        return getAllDaysInMonth();
      case TimelineRange.quarter:
        final start = getMonthStart();
        final end = start.addMonths(3).subtractDays(1);
        final days = <LocalDate>[];
        var current = start;
        while (current <= end) {
          days.add(current);
          current = current.addDays(1);
        }
        return days;
    }
  }

  void goToPreviousRange(TimelineRange range) {
    switch (range) {
      case TimelineRange.week:
        state = state.subtractDays(7);
      case TimelineRange.month:
        goToPreviousMonth();
      case TimelineRange.quarter:
        state = getMonthStart().subtractMonths(3);
    }
  }

  void goToNextRange(TimelineRange range) {
    switch (range) {
      case TimelineRange.week:
        state = state.addDays(7);
      case TimelineRange.month:
        goToNextMonth();
      case TimelineRange.quarter:
        state = getMonthStart().addMonths(3);
    }
  }
}

final timelineDateNotifierProvider =
    StateNotifierProvider<TimelineDateNotifier, LocalDate>((ref) {
      return TimelineDateNotifier();
    });
