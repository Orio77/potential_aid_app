import 'package:potential_aid_app/data/tables/block.dart';
import 'package:time_machine/time_machine.dart';

class ScheduleBlockService {
  static bool isBlockTimePassed(
    BlockWithTasks blockWithTasks,
    LocalDateTime currentTime,
  ) {
    final blockDate = blockWithTasks.block.dayLocal;
    final currentDate = currentTime.toDateTimeLocal();

    if (!isSameDay(blockDate, currentDate)) {
      return false;
    }

    final currentMinutes =
        currentTime.hourOfDay * 60 + currentTime.minuteOfHour;
    final blockStartMinutes = blockWithTasks.block.startMinuteOfDay;

    return currentMinutes > blockStartMinutes;
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool isBlockInFuture(
    BlockWithTasks blockWithTasks,
    LocalDateTime currentDateTime,
  ) {
    final blockDate = blockWithTasks.block.dayLocal;
    final currentDate = DateTime(
      currentDateTime.yearOfEra,
      currentDateTime.monthOfYear,
      currentDateTime.dayOfMonth,
    );

    final blockDateNormalized = DateTime(
      blockDate.year,
      blockDate.month,
      blockDate.day,
    );
    final currentDateNormalized = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    return blockDateNormalized.isAfter(currentDateNormalized);
  }

  static bool canCompleteBlock(
    BlockWithTasks blockWithTasks,
    LocalDateTime dateTime,
    bool isPreviousBlockCompleted,
  ) {
    final isBlockToday =
        blockWithTasks.block.dayLocal.day == dateTime.dayOfMonth &&
        blockWithTasks.block.dayLocal.month == dateTime.monthOfYear &&
        blockWithTasks.block.dayLocal.year == dateTime.yearOfEra;

    return (isPreviousBlockCompleted && isBlockToday) ||
        isBlockTimePassed(blockWithTasks, dateTime);
  }
}
