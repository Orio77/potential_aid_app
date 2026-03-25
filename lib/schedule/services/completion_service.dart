class CompletionService {
  static double fieldWidth(int max) {
    const double base = 36;
    const double perDigit = 12;
    final int digits = max.toString().length.clamp(2, 3);
    return base + perDigit * digits;
  }

  static int? calculateTaskDelta(int inputValue, int currentValue) {
    final int delta = inputValue - currentValue;
    if (delta <= currentValue) {
      return null;
    }
    return delta;
  }
}
