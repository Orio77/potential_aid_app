import 'package:flutter/material.dart';

class CompletionUtils {
  static Color getCompletionColor(double completionPercentage) {
    if (completionPercentage == 0) {
      return Colors.grey;
    } else if (completionPercentage < 25) {
      return Colors.red;
    } else if (completionPercentage < 50) {
      return Colors.orange;
    } else if (completionPercentage < 75) {
      return Colors.amber;
    } else if (completionPercentage < 100) {
      return Colors.lightGreen;
    } else {
      return Colors.green;
    }
  }
}
