import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/l10n/app_locale.dart';
import '../../core/responsive/responsive.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';

class OnboardingIntroPage extends StatelessWidget {
  const OnboardingIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final horizontalPadding = Responsive.responsiveHorizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(
                context,
                mobile: 520,
                tablet: 620,
                desktop: 680,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    28,
                    horizontalPadding,
                    0,
                  ),
                  child: Column(
                    children: [
                      Text(
                        locale.tr('onboarding_intro_title'),
                        maxLines: 3,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: AppColors.heading,
                              fontWeight: FontWeight.w800,
                              fontSize: 34,
                              height: 1.08,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 390),
                        child: Text(
                          locale.tr('onboarding_intro_subtitle'),
                          maxLines: 4,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.mutedText,
                                height: 1.5,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Semantics(
                    image: true,
                    label: locale.tr('onboarding_intro_title'),
                    child: const _IntroHeroImage(),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.pageBackground,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.outline.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      18,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          label: locale.tr('onboarding_intro_start'),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.onboarding,
                          ),
                        ),
                      ],
                    ),
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

class _IntroHeroImage extends StatelessWidget {
  const _IntroHeroImage();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = constraints.maxWidth * 1.5;

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImageLayer(imageWidth),
              Positioned.fill(
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black45,
                        Colors.black,
                      ],
                      stops: [0, 0.8, 0.92, 1],
                    ).createShader(rect);
                  },
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: _buildImageLayer(imageWidth),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.pageBackground.withValues(alpha: 0),
                        AppColors.pageBackground.withValues(alpha: 0),
                        AppColors.pageBackground.withValues(alpha: 0.42),
                        AppColors.pageBackground,
                      ],
                      stops: const [0, 0.84, 0.96, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 44,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.pageBackground.withValues(alpha: 0),
                        AppColors.pageBackground.withValues(alpha: 0.92),
                        AppColors.pageBackground,
                      ],
                      stops: const [0, 0.7, 1],
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 8,
                child: ColoredBox(color: AppColors.pageBackground),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageLayer(double imageWidth) {
    return OverflowBox(
      alignment: Alignment.topCenter,
      minWidth: imageWidth,
      maxWidth: imageWidth,
      minHeight: 0,
      maxHeight: double.infinity,
      child: Transform.translate(
        offset: const Offset(0, -18),
        child: Image.asset(
          'img/logo_onboard-perfect.png',
          width: imageWidth,
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }
}
