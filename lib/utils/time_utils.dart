import 'package:flutter/material.dart';

class TimeUtils {
  static int datetimeToMinutes(TimeOfDay datetime) {
    return datetime.hour * 60 + datetime.minute;
  }

  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
