import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_machine/time_machine.dart';

class DateNotifier extends StateNotifier<LocalDate> {
  DateNotifier() : super(LocalDate.today());

  void goToNextDay() {
    state = state.addDays(1);
  }

  void goToPreviousDay() {
    state = state.addDays(-1);
  }

  void goToDay(LocalDate targetDate) {
    state = targetDate;
  }

  void goToToday() {
    state = LocalDate.today();
  }
}

final dateNotifierProvider = StateNotifierProvider<DateNotifier, LocalDate>((
  ref,
) {
  return DateNotifier();
});
