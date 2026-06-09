import 'package:flutter/material.dart';

import '../../core/mock/mock_skin_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass_header.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/selectable_option_card.dart';

class QuizAnswer {
  const QuizAnswer({
    this.skinType,
    this.concerns = const [],
    this.budget,
    this.photoSource,
  });

  final String? skinType;
  final List<String> concerns;
  final String? budget;
  final String? photoSource;

  QuizAnswer copyWith({
    String? skinType,
    List<String>? concerns,
    String? budget,
    String? photoSource,
  }) {
    return QuizAnswer(
      skinType: skinType ?? this.skinType,
      concerns: concerns ?? this.concerns,
      budget: budget ?? this.budget,
      photoSource: photoSource ?? this.photoSource,
    );
  }
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int step = 0;
  bool isSubmitting = false;
  QuizAnswer answer = const QuizAnswer();

  @override
  Widget build(BuildContext context) {
    final progress = (step + 1) / 4;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const GlassHeader(
        currentRoute: AppRoutes.quiz,
        title: 'Skin Quiz',
      ),
      body: ResponsiveContainer(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.pagePadding,
                    AppSpacing.pagePadding,
                    AppSpacing.pagePadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Step ${step + 1} of 4', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: AppColors.secondary,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _buildStep(context),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  decoration: BoxDecoration(
                    color: AppColors.pageBackground,
                    border: Border(
                      top: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GradientPillButton(
                        label: step == 3 ? 'Analyze My Skin' : 'Continue',
                        isLoading: isSubmitting,
                        expanded: true,
                        onPressed: _handleContinue,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: step == 0
                            ? () => Navigator.of(context).maybePop()
                            : () => setState(() => step -= 1),
                        child: Text(step == 0 ? 'Back' : 'Previous'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    if (step < 3) {
      setState(() => step += 1);
      return;
    }

    setState(() => isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.analysis);
  }

  Widget _buildStep(BuildContext context) {
    switch (step) {
      case 0:
        return _QuizStepLayout(
          key: const ValueKey('skinType'),
          title: 'What best describes your skin type?',
          subtitle: 'Pick the option that feels closest to your day-to-day skin behavior.',
          child: Column(
            children: MockSkinData.quizSkinTypes
                .map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SelectableOptionCard(
                      title: type,
                      description: 'Balanced for touch-first selection on mobile.',
                      selected: answer.skinType == type,
                      icon: Icons.spa_outlined,
                      onTap: () => setState(() => answer = answer.copyWith(skinType: type)),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      case 1:
        return _QuizStepLayout(
          key: const ValueKey('concerns'),
          title: 'Which concerns are you noticing most?',
          subtitle: 'Choose the skin concerns you want SkinSync to prioritize.',
          child: Column(
            children: MockSkinData.quizConcerns.map((concern) {
              final selected = answer.concerns.contains(concern);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SelectableOptionCard(
                  title: concern,
                  description: 'Tap to include this in your AI profile.',
                  selected: selected,
                  icon: Icons.check_circle_outline_rounded,
                  onTap: () {
                    final next = [...answer.concerns];
                    if (selected) {
                      next.remove(concern);
                    } else {
                      next.add(concern);
                    }
                    setState(() => answer = answer.copyWith(concerns: next));
                  },
                ),
              );
            }).toList(),
          ),
        );
      case 2:
        return _QuizStepLayout(
          key: const ValueKey('budget'),
          title: 'What is your skincare budget?',
          subtitle: 'This helps tailor recommendations to product tiers that feel realistic.',
          child: Column(
            children: MockSkinData.budgets
                .map(
                  (budget) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SelectableOptionCard(
                      title: budget,
                      description: 'We will adapt the routine product mix around this level.',
                      selected: answer.budget == budget,
                      icon: Icons.sell_outlined,
                      onTap: () => setState(() => answer = answer.copyWith(budget: budget)),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      default:
        return _QuizStepLayout(
          key: const ValueKey('upload'),
          title: 'Upload your skin photo',
          subtitle: 'Use bright lighting, face forward, and avoid heavy filters.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: answer.photoSource == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined, size: 48, color: AppColors.primaryDark),
                                SizedBox(height: 12),
                                Text('Add a clear selfie'),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.network(
                                MockSkinData.analysis.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(color: Colors.white),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() {
                              answer = answer.copyWith(photoSource: 'camera');
                            }),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Take Photo'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() {
                              answer = answer.copyWith(photoSource: 'gallery');
                            }),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Choose Gallery'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _UploadTip(icon: Icons.light_mode_outlined, text: 'Good lighting'),
              const SizedBox(height: 10),
              const _UploadTip(icon: Icons.face_rounded, text: 'Face forward'),
              const SizedBox(height: 10),
              const _UploadTip(icon: Icons.filter_alt_off_outlined, text: 'No heavy filter'),
            ],
          ),
        );
    }
  }
}

class _QuizStepLayout extends StatelessWidget {
  const _QuizStepLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 20),
        child,
      ],
    );
  }
}

class _UploadTip extends StatelessWidget {
  const _UploadTip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryDark),
          const SizedBox(width: 10),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
