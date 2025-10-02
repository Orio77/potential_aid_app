import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_machine/time_machine.dart';

class TimelineDateNotifier extends StateNotifier<LocalDate> {
  TimelineDateNotifier() : super(LocalDate.today());

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
}

final timelineDateNotifierProvider =
    StateNotifierProvider<TimelineDateNotifier, LocalDate>((ref) {
      return TimelineDateNotifier();
    });
