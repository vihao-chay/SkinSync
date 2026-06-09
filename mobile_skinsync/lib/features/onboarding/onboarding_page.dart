import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/responsive_container.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentIndex = 0;

  static const _slides = [
    _OnboardingData(
      title: 'Understand Your Skin',
      subtitle: 'Get AI-powered insights from your skin photo.',
      icon: Icons.face_retouching_natural_rounded,
    ),
    _OnboardingData(
      title: 'Build Your Routine',
      subtitle: 'Receive a personalized morning and night skincare plan.',
      icon: Icons.spa_rounded,
    ),
    _OnboardingData(
      title: 'Track Your Progress',
      subtitle: 'Log your routine and watch your skin journey improve.',
      icon: Icons.calendar_month_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentIndex == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ResponsiveContainer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                    child: const Text('Skip'),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (index) => setState(() => _currentIndex = index),
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return _OnboardingSlide(data: slide);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (index) {
                    final selected = index == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: selected ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.largeGap),
                GradientPillButton(
                  label: isLast ? 'Get Started' : 'Next',
                  expanded: true,
                  onPressed: () {
                    if (isLast) {
                      Navigator.pushReplacementNamed(context, AppRoutes.quiz);
                      return;
                    }
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.mediumGap),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                    child: const Text('Sign In'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.data});

  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              colors: [AppColors.secondary, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 42,
                left: 42,
                child: _SoftBubble(size: 72, color: AppColors.softPink.withValues(alpha: 0.8)),
              ),
              Positioned(
                right: 36,
                bottom: 54,
                child: _SoftBubble(size: 96, color: AppColors.accent.withValues(alpha: 0.45)),
              ),
              CircleAvatar(
                radius: 58,
                backgroundColor: Colors.white,
                child: Icon(data.icon, size: 54, color: AppColors.primaryDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Text(
          data.subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedText,
              ),
        ),
      ],
    );
  }
}

class _SoftBubble extends StatelessWidget {
  const _SoftBubble({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}
