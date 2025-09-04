import 'package:flutter/material.dart';

class CompletionUtils {
  static Color getCompletionColor(double completionPercentage) {
    final clamped = completionPercentage.clamp(0.0, 100.0);

    if (clamped == 0) return Colors.grey.shade300;
    if (clamped == 100) return Colors.green.shade600;

    final colorStops = [
      _ColorStop(0, Colors.red.shade400),
      _ColorStop(25, Colors.orange.shade400),
      _ColorStop(50, Colors.amber.shade400),
      _ColorStop(75, Colors.lightGreen.shade400),
      _ColorStop(100, Colors.green.shade600),
    ];

    return _interpolateColor(clamped, colorStops);
  }

  static Color getCompletionColorM3(
    double completionPercentage,
    ColorScheme colorScheme,
  ) {
    final clamped = completionPercentage.clamp(0.0, 100.0);

    if (clamped == 0) return colorScheme.outline;
    if (clamped == 100) return colorScheme.primary;

    final colorStops = [
      _ColorStop(0, colorScheme.error),
      _ColorStop(30, colorScheme.tertiary),
      _ColorStop(70, colorScheme.secondary),
      _ColorStop(100, colorScheme.primary),
    ];

    return _interpolateColor(clamped, colorStops);
  }

  static String getCompletionText(double completionPercentage) {
    final clamped = completionPercentage.clamp(0.0, 100.0);

    if (clamped == 0) return 'Not started';
    if (clamped == 100) return 'Complete';
    if (clamped < 10) return 'Just started';
    if (clamped < 25) return 'Getting started';
    if (clamped < 50) return 'Making progress';
    if (clamped < 75) return 'Well underway';
    if (clamped < 90) return 'Nearly there';
    return 'Almost complete';
  }

  static Color _interpolateColor(
    double percentage,
    List<_ColorStop> colorStops,
  ) {
    for (int i = 0; i < colorStops.length - 1; i++) {
      final current = colorStops[i];
      final next = colorStops[i + 1];

      if (percentage >= current.percentage && percentage <= next.percentage) {
        final t =
            (percentage - current.percentage) /
            (next.percentage - current.percentage);
        return Color.lerp(current.color, next.color, t)!;
      }
    }

    return colorStops.last.color;
  }
}

class _ColorStop {
  final double percentage;
  final Color color;

  const _ColorStop(this.percentage, this.color);
}
