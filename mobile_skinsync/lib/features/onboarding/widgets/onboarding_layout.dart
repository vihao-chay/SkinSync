import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class OnboardingLayout extends StatelessWidget {
  const OnboardingLayout({
    super.key,
    required this.progress,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.child,
    required this.bottomBar,
  });

  final double progress;
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final Widget child;
  final Widget bottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (onBack != null)
                        IconButton(
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        )
                      else
                        const SizedBox(width: 48),
                      Expanded(child: Text('SkinSync', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700))),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OnboardingProgressBar(progress: progress),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 28, height: 1.1, fontWeight: FontWeight.w800, color: AppColors.foreground),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 15, height: 1.45, color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: child,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}

class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 8,
        value: progress.clamp(0, 1),
        backgroundColor: AppColors.secondary,
        valueColor: const AlwaysStoppedAnimation(AppColors.primaryDark),
      ),
    );
  }
}
