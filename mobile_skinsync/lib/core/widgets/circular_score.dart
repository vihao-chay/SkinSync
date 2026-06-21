import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum CircularScoreTone { health, severity }

class CircularScore extends StatelessWidget {
  const CircularScore({
    super.key,
    required this.score,
    this.size = 96,
    this.label = 'Skin score',
    this.suffix = '',
    this.progressColor,
  });

  final int score;
  final double size;
  final String label;
  final String suffix;
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0, 100);
    final color = progressColor ?? AppColors.primary;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: clamped / 100),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return CustomPaint(
            painter: _CircularScorePainter(progress: value, color: color),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$clamped$suffix',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontFamily: 'PlayfairDisplay',
                      color: AppColors.heading,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CircularScorePainter extends CustomPainter {
  const _CircularScorePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.1;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = AppColors.surfaceContainerHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final arc = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [color.withValues(alpha: 0.55), color],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(covariant _CircularScorePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
