import 'package:flutter/material.dart';

class Responsive {
  const Responsive._();

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static bool isSmallMobile(BuildContext context) => screenWidth(context) < 360;

  static bool isMobile(BuildContext context) {
    final width = screenWidth(context);
    return width >= 360 && width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = screenWidth(context);
    return width >= 600 && width < 1024;
  }

  static bool isDesktop(BuildContext context) => screenWidth(context) >= 1024;

  static T responsiveValue<T>(
    BuildContext context, {
    T? mobileSmall,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (isTablet(context)) {
      return tablet ?? mobile;
    }
    if (isSmallMobile(context)) {
      return mobileSmall ?? mobile;
    }
    return mobile;
  }

  static double responsiveSpacing(BuildContext context) {
    return responsiveValue<double>(
      context,
      mobileSmall: 12,
      mobile: 16,
      tablet: 24,
      desktop: 32,
    );
  }

  static double responsiveHorizontalPadding(BuildContext context) {
    return responsiveValue<double>(
      context,
      mobileSmall: 12,
      mobile: 16,
      tablet: 24,
      desktop: 32,
    );
  }

  static EdgeInsets responsivePadding(
    BuildContext context, {
    double top = 0,
    double bottom = 0,
    double? horizontal,
  }) {
    final horizontalValue = horizontal ?? responsiveHorizontalPadding(context);
    return EdgeInsets.fromLTRB(horizontalValue, top, horizontalValue, bottom);
  }

  static double topSafeArea(BuildContext context) =>
      MediaQuery.viewPaddingOf(context).top;

  static double bottomSafeArea(BuildContext context) =>
      MediaQuery.viewPaddingOf(context).bottom;

  static double contentBottomSpacing(
    BuildContext context, {
    double extra = 20,
  }) {
    return bottomSafeArea(context) + extra;
  }

  static double floatingNavigationBottomSpacing(
    BuildContext context, {
    double extra = 20,
  }) {
    const navigationHeight = 64.0;
    const navigationBottomMargin = 8.0;
    return bottomSafeArea(context) +
        navigationHeight +
        navigationBottomMargin +
        extra;
  }

  static double headerTopSpacing(BuildContext context, {bool compact = false}) {
    return responsiveValue<double>(
      context,
      mobileSmall: compact ? 8 : 12,
      mobile: compact ? 10 : 16,
      tablet: compact ? 14 : 20,
      desktop: compact ? 16 : 24,
    );
  }

  static double maxContentWidth(
    BuildContext context, {
    double mobile = double.infinity,
    double tablet = 720,
    double desktop = 1040,
  }) {
    if (isDesktop(context)) {
      return desktop;
    }
    if (isTablet(context)) {
      return tablet;
    }
    return mobile;
  }

  static int columns(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    if (isDesktop(context)) {
      return desktop;
    }
    if (isTablet(context)) {
      return tablet;
    }
    return mobile;
  }

  static int gridColumns(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    return columns(context, mobile: mobile, tablet: tablet, desktop: desktop);
  }
}
