import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TimelineDensity { compact, normal, wide }

extension TimelineDensityX on TimelineDensity {
  double get cardWidth {
    switch (this) {
      case TimelineDensity.compact:
        return 120.0;
      case TimelineDensity.normal:
        return 250.0;
      case TimelineDensity.wide:
        return 400.0;
    }
  }

  String get label {
    switch (this) {
      case TimelineDensity.compact:
        return 'C';
      case TimelineDensity.normal:
        return 'N';
      case TimelineDensity.wide:
        return 'W';
    }
  }
}

final timelineDensityProvider =
    StateProvider<TimelineDensity>((ref) => TimelineDensity.normal);
