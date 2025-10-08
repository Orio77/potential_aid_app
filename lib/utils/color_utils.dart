import 'package:flutter/material.dart';

// Purely AI Generated
class ColorUtils {
  /// Creates a northern lights-style gradient that starts intense at the bottom
  /// and fades above the vertical middle, similar to aurora borealis
  static LinearGradient createNorthernLightsGradient({
    required Color baseColor,
    double? stopAt,
  }) {
    return LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      stops: [
        0.0, // Bottom edge - most intense
        (stopAt ?? 0.35) * 0.4, // 30% up - still strong
        (stopAt ?? 0.35) * 0.7, // 60% up - fading
        (stopAt ?? 0.35) * 0.9, // 80% up - very faint
        stopAt ?? 0.35, // Top - transparent
      ],
      colors: [
        baseColor.withValues(alpha: 0.8), // Intense at bottom
        baseColor.withValues(alpha: 0.6), // Strong
        baseColor.withValues(alpha: 0.3), // Fading
        baseColor.withValues(alpha: 0.1), // Very faint
        baseColor.withValues(alpha: 0.0), // Transparent at top
      ],
    );
  }

  /// Creates a more dramatic northern lights effect with shimmer
  static LinearGradient createDramaticNorthernLights(Color baseColor) {
    final shimmerColor = HSLColor.fromColor(
      baseColor,
    ).withLightness(0.8).withSaturation(0.7).toColor();

    return LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      stops: const [0.0, 0.2, 0.4, 0.7, 1.0],
      colors: [
        baseColor.withValues(alpha: 0.9), // Intense base
        shimmerColor.withValues(alpha: 0.7), // Shimmer effect
        baseColor.withValues(alpha: 0.4), // Mid fade
        baseColor.withValues(alpha: 0.1), // Light fade
        Colors.transparent, // Transparent top
      ],
    );
  }

  static LinearGradient createNorthernLightsBorder(Color baseColor) {
    final accentColor = HSLColor.fromColor(
      baseColor,
    ).withLightness(0.7).withSaturation(0.8).toColor();

    return LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      stops: const [0.0, 0.3, 0.7, 1.0],
      colors: [
        baseColor.withValues(alpha: 0.6), // Intense at bottom-left
        accentColor.withValues(alpha: 0.4), // Shimmer mid-tone
        baseColor.withValues(alpha: 0.3), // Fade
        baseColor.withValues(alpha: 0.1), // Very subtle at top-right
      ],
    );
  }

  /// Creates an edge-focused gradient that's intense at all borders and fades inward
  /// [fadeDistance] controls how far the gradient reaches inward (0.0 to 1.0)
  /// 0.1 = very thin border, 0.5 = reaches halfway to center, 1.0 = reaches center
  static RadialGradient createEdgeIntenseBorder(
    Color baseColor, {
    double fadeDistance = 0.15,
  }) {
    final accentColor = HSLColor.fromColor(
      baseColor,
    ).withLightness(0.8).withSaturation(0.9).toColor();

    // Clamp fadeDistance to valid range
    final clampedDistance = fadeDistance.clamp(0.05, 1.0);

    return RadialGradient(
      center: Alignment.center,
      radius: 1.4, // Extends beyond container to ensure edges are covered
      stops: [
        0.0, // Center
        1.0 - clampedDistance, // Start of fade zone
        1.0 - (clampedDistance * 0.7), // Mid fade
        1.0 - (clampedDistance * 0.3), // Near edge
        1.0, // Edge
      ],
      colors: [
        Colors.transparent, // Transparent center
        Colors.transparent, // Still transparent before fade starts
        baseColor.withValues(alpha: 0.2), // Begin fade
        accentColor.withValues(alpha: 0.6), // Shimmer near edge
        baseColor.withValues(alpha: 0.9), // Intense at edge
      ],
    );
  }

  static LinearGradient createSunsetDreams(Color baseColor) {
    final warmAccent = HSLColor.fromColor(baseColor)
        .withHue((HSLColor.fromColor(baseColor).hue + 30) % 360)
        .withSaturation(0.8)
        .withLightness(0.7)
        .toColor();

    final deepShadow = HSLColor.fromColor(baseColor)
        .withHue((HSLColor.fromColor(baseColor).hue - 20) % 360)
        .withSaturation(0.9)
        .withLightness(0.3)
        .toColor();

    return LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      colors: [
        deepShadow.withValues(alpha: 0.9), // Rich bottom shadow
        baseColor.withValues(alpha: 0.8), // Main color
        warmAccent.withValues(alpha: 0.6), // Warm mid-tone
        warmAccent.withValues(alpha: 0.3), // Soft highlight
        Colors.white.withValues(alpha: 0.1), // Ethereal top
      ],
    );
  }

  /// Creates an oceanic wave gradient with flowing blue-green transitions
  static LinearGradient createOceanWaves(Color baseColor) {
    final deepOcean = HSLColor.fromColor(baseColor)
        .withHue(200) // Blue tone
        .withSaturation(0.8)
        .withLightness(0.2)
        .toColor();

    final seafoam = HSLColor.fromColor(baseColor)
        .withHue(180) // Cyan-green tone
        .withSaturation(0.6)
        .withLightness(0.7)
        .toColor();

    final crystalBlue = HSLColor.fromColor(baseColor)
        .withHue(210) // Crystal blue
        .withSaturation(0.7)
        .withLightness(0.5)
        .toColor();

    return LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
      colors: [
        deepOcean.withValues(alpha: 0.95), // Deep ocean floor
        crystalBlue.withValues(alpha: 0.8), // Mid-depth water
        baseColor.withValues(alpha: 0.6), // Surface blend
        seafoam.withValues(alpha: 0.4), // Seafoam bubbles
        Colors.white.withValues(alpha: 0.05), // Surface sparkle
      ],
    );
  }
}
