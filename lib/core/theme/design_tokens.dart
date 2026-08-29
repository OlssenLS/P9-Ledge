import 'package:flutter/material.dart';

class Spacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class Radii {
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

class Insets {
  static const EdgeInsets screen = EdgeInsets.all(Spacing.md);
  static const EdgeInsets card = EdgeInsets.all(Spacing.md);
  static const EdgeInsets bottomSheet = EdgeInsets.only(
    top: Spacing.lg,
    left: Spacing.md,
    right: Spacing.md,
    bottom: Spacing.xl,
  );
}
