import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DateCardList extends ConsumerWidget {
  final double dayCardWidth;
  final double dayCardHeight;
  final int daysOfMonth;
  const DateCardList({
    super.key,
    required this.dayCardWidth,
    required this.dayCardHeight,
    required this.daysOfMonth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight =
        MediaQuery.of(context).size.height - kToolbarHeight - 4;

    return _buildDateCards(screenHeight);
  }

  Widget _buildDateCards(double screenHeight) {
    return Row(
      children: List.generate(daysOfMonth, (index) {
        return SizedBox(
          width: dayCardWidth,
          child: Column(
            children: [
              SizedBox(
                height: dayCardHeight,
                width: double.infinity,
                child: Card(child: Center(child: Text("Day ${index + 1}"))),
              ),
            ],
          ),
        );
      }),
    );
  }
}
