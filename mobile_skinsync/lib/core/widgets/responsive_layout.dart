import 'package:flutter/material.dart';

import '../responsive/responsive.dart';

class ResponsiveLayout {
  const ResponsiveLayout._();

  static double screenWidth(BuildContext context) =>
      Responsive.screenWidth(context);

  static bool isCompact(BuildContext context) =>
      Responsive.isSmallMobile(context);

  static bool isMedium(BuildContext context) => Responsive.isTablet(context);

  static bool isLarge(BuildContext context) => Responsive.isDesktop(context);

  static double horizontalPadding(BuildContext context) =>
      Responsive.responsiveHorizontalPadding(context);

  static double contentMaxWidth(
    BuildContext context, {
    double compact = 460,
    double medium = 720,
    double large = 1040,
  }) {
    return Responsive.maxContentWidth(
      context,
      mobile: compact,
      tablet: medium,
      desktop: large,
    );
  }

  static int columns(
    BuildContext context, {
    int compact = 1,
    int medium = 2,
    int large = 3,
  }) {
    return Responsive.columns(
      context,
      mobile: compact,
      tablet: medium,
      desktop: large,
    );
  }

  static double itemWidth(
    BuildContext context, {
    required double spacing,
    int compact = 1,
    int medium = 2,
    int large = 3,
  }) {
    final cols = columns(
      context,
      compact: compact,
      medium: medium,
      large: large,
    );
    return (screenWidth(context) - (spacing * (cols - 1))) / cols;
  }
}
