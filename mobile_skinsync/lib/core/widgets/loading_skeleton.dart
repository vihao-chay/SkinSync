import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 14,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + (_controller.value * 2), 0),
              end: Alignment(1 + (_controller.value * 2), 0),
              colors: const [
                AppColors.surfaceStrong,
                Colors.white,
                AppColors.surfaceStrong,
              ],
            ),
          ),
        );
      },
    );
  }
}
