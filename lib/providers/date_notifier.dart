import 'dart:async';

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

class DateTimeNotifier extends StateNotifier<LocalDateTime> {
  Timer? _timer;

  DateTimeNotifier() : super(_getCurrentLocalDateTime()) {
    _startTimer();
  }

  static LocalDateTime _getCurrentLocalDateTime() {
    // Use system timezone to get the correct local time
    final now = DateTime.now();
    final localDateTime = LocalDateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
    );
    return localDateTime;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Temporary: 10 seconds for testing
      final currentTime = _getCurrentLocalDateTime();
      state = currentTime;
    });
  }

  void updateToNow() {
    state = _getCurrentLocalDateTime();
  }

  void goToDateTime(LocalDateTime targetDateTime) {
    state = targetDateTime;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final dateNotifierProvider = StateNotifierProvider<DateNotifier, LocalDate>((
  ref,
) {
  return DateNotifier();
});

final dateTimeNotifierProvider =
    StateNotifierProvider<DateTimeNotifier, LocalDateTime>((ref) {
      return DateTimeNotifier();
    });
