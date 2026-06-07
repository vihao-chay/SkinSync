import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 42,
    this.borderRadius = 14,
    this.borderColor,
    this.boxShadow,
  });

  final double size;
  final double borderRadius;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFBF6EF),
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor == null ? null : Border.all(color: borderColor!),
        boxShadow: boxShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/logo.jpg',
        fit: BoxFit.cover,
        semanticLabel: 'SkinSync logo',
      ),
    );
  }
}
