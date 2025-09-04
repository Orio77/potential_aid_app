import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// TODO
class BarMap extends StatelessWidget {
  const BarMap({super.key});

  @override
  Widget build(BuildContext context) {
    final barGroupData = List.generate(30, (i) {
      return BarChartGroupData(
        x: i + 1,
        barRods: [BarChartRodData(toY: Random().nextDouble() * 10, width: 10)],
      );
    });

    final data = BarChartData(barGroups: barGroupData);

    return BarChart(data);
  }
}
