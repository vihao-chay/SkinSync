import 'package:flutter/material.dart';

class ResponsiveLayout {
  const ResponsiveLayout._();

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) => screenWidth(context) < 360;

  static bool isMedium(BuildContext context) => screenWidth(context) >= 600;

  static bool isLarge(BuildContext context) => screenWidth(context) >= 960;

  static double horizontalPadding(BuildContext context) {
    final width = screenWidth(context);
    if (width >= 1280) {
      return 32;
    }
    if (width >= 960) {
      return 28;
    }
    if (width >= 600) {
      return 24;
    }
    return 20;
  }

  static double contentMaxWidth(
    BuildContext context, {
    double compact = 460,
    double medium = 720,
    double large = 1040,
  }) {
    final width = screenWidth(context);
    if (width >= 1280) {
      return large;
    }
    if (width >= 600) {
      return medium;
    }
    return compact;
  }

  static int columns(
    BuildContext context, {
    int compact = 1,
    int medium = 2,
    int large = 3,
  }) {
    final width = screenWidth(context);
    if (width >= 960) {
      return large;
    }
    if (width >= 600) {
      return medium;
    }
    return compact;
  }

  static double itemWidth(
    BuildContext context, {
    required double spacing,
    int compact = 1,
    int medium = 2,
    int large = 3,
  }) {
    final width = screenWidth(context);
    final cols = columns(
      context,
      compact: compact,
      medium: medium,
      large: large,
    );
    return (width - (spacing * (cols - 1))) / cols;
  }
}
