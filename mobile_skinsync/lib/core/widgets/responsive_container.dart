import 'package:flutter/material.dart';

import '../responsive/responsive.dart';

class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.topPadding = 0,
    this.bottomPadding = 0,
  });

  final Widget child;
  final double? maxWidth;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final resolvedMaxWidth =
        maxWidth ??
        Responsive.maxContentWidth(
          context,
          mobile: double.infinity,
          tablet: 720,
          desktop: 1040,
        );
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: resolvedMaxWidth),
        child: Padding(
          padding: Responsive.responsivePadding(
            context,
            top: topPadding,
            bottom: bottomPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}
