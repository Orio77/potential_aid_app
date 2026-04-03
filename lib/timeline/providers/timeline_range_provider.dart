import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TimelineRange { week, month, quarter }

extension TimelineRangeX on TimelineRange {
  String get label {
    switch (this) {
      case TimelineRange.week:
        return 'W';
      case TimelineRange.month:
        return 'M';
      case TimelineRange.quarter:
        return 'Q';
    }
  }
}

final timelineRangeProvider =
    StateProvider<TimelineRange>((ref) => TimelineRange.month);
