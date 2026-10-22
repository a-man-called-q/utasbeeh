import 'package:flutter/painting.dart';
import 'package:mix/mix.dart';

/// Spacing scale. Shared by every theme: themes change color only.
abstract final class AppSpace {
  static const xs = SpaceToken('space.xs');
  static const sm = SpaceToken('space.sm');
  static const md = SpaceToken('space.md');
  static const lg = SpaceToken('space.lg');
  static const xl = SpaceToken('space.xl');
  static const xxl = SpaceToken('space.xxl');

  static final Map<SpaceToken, double> scale = {
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 24,
    xxl: 32,
  };
}

/// Corner radii. Glass uses [lg] and [pill]; the rest is for plain surfaces.
abstract final class AppRadius {
  static const sm = RadiusToken('radius.sm');
  static const md = RadiusToken('radius.md');
  static const lg = RadiusToken('radius.lg');
  static const pill = RadiusToken('radius.pill');

  static final Map<RadiusToken, Radius> scale = {
    sm: Radius.circular(8),
    md: Radius.circular(14),
    lg: Radius.circular(22),
    pill: Radius.circular(999),
  };
}
