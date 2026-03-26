import 'dart:async';
import 'package:flutter/material.dart';

// Mixin for widgets that need auto-scroll functionality
mixin AutoScrollMixin<T extends StatefulWidget> on State<T> {
  Timer? _scrollTimer;
  static const double _defaultScrollZoneWidth = 50.0;
  static const double _defaultScrollSpeed = 200.0; // Increased base speed

  // Scroll zone percentages
  static const double _fastScrollZonePercent = 0.05; // 5% of screen width
  static const double _mediumScrollZonePercent = 0.1; // 10% of screen width
  static const double _slowScrollZonePercent = 0.15; // 15% of screen width

  // Speed multipliers
  static const double _fastScrollMultiplier = 8.0;
  static const double _mediumScrollMultiplier = 4.0;
  static const double _slowScrollMultiplier = 2.0;

  // Callback for scroll offset changes - per instance
  void Function(double scrollDelta)? _onScrollOffsetChanged;

  ScrollController? get scrollController;
  double get scrollZoneWidth => _defaultScrollZoneWidth;
  double get scrollSpeed => _defaultScrollSpeed;

  void setScrollOffsetChangeCallback(
    void Function(double scrollDelta)? callback,
  ) {
    _onScrollOffsetChanged = callback;
  }

  @override
  void dispose() {
    stopAutoScroll();
    super.dispose();
  }

  void stopAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
  }

  void startAutoScroll(double direction) {
    startAutoScrollWithSpeed(direction, scrollSpeed);
  }

  void startAutoScrollWithSpeed(double direction, double speed) {
    stopAutoScroll();

    if (scrollController == null) return;

    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final controller = scrollController!;
      final oldOffset = controller.offset;
      final newOffset = controller.offset + (direction * speed * 0.016);

      if (newOffset < 0) {
        controller.jumpTo(0);
        stopAutoScroll();
      } else if (newOffset > controller.position.maxScrollExtent) {
        controller.jumpTo(controller.position.maxScrollExtent);
        stopAutoScroll();
      } else {
        controller.jumpTo(newOffset);

        // Notify about scroll offset change for drag overlay updates
        final scrollDelta = controller.offset - oldOffset;
        _onScrollOffsetChanged?.call(scrollDelta);
      }
    });
  }

  void checkAutoScroll(Offset globalPosition) {
    if (scrollController == null) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final x = globalPosition.dx;

    // Define scroll zones based on screen width
    final fastScrollZone = screenWidth * _fastScrollZonePercent;
    final mediumScrollZone = screenWidth * _mediumScrollZonePercent;
    final slowScrollZone = screenWidth * _slowScrollZonePercent;

    double scrollMultiplier = 0;
    double direction = 0;

    if (x < fastScrollZone) {
      // Very fast left scroll at extreme edge
      direction = -1;
      scrollMultiplier = _fastScrollMultiplier;
    } else if (x < mediumScrollZone) {
      // Medium left scroll
      direction = -1;
      scrollMultiplier = _mediumScrollMultiplier;
    } else if (x < slowScrollZone) {
      // Slow left scroll
      direction = -1;
      scrollMultiplier = _slowScrollMultiplier;
    } else if (x > screenWidth - fastScrollZone) {
      // Very fast right scroll at extreme edge
      direction = 1;
      scrollMultiplier = _fastScrollMultiplier;
    } else if (x > screenWidth - mediumScrollZone) {
      // Medium right scroll
      direction = 1;
      scrollMultiplier = _mediumScrollMultiplier;
    } else if (x > screenWidth - slowScrollZone) {
      // Slow right scroll
      direction = 1;
      scrollMultiplier = _slowScrollMultiplier;
    }

    if (scrollMultiplier > 0) {
      startAutoScrollWithSpeed(direction, scrollSpeed * scrollMultiplier);
    } else {
      stopAutoScroll();
    }
  }
}
