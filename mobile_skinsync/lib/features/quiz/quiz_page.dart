import 'package:flutter/material.dart';

import '../../core/mock/mock_skin_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/glass_header.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/selectable_option_card.dart';
import '../../core/widgets/section_badge.dart';

class QuizAnswer {
  const QuizAnswer({
    this.skinType,
    this.concerns = const [],
    this.budget,
    this.imagePath,
  });

  final String? skinType;
  final List<String> concerns;
  final String? budget;
  final String? imagePath;

  QuizAnswer copyWith({
    String? skinType,
    List<String>? concerns,
    String? budget,
    String? imagePath,
  }) {
    return QuizAnswer(
      skinType: skinType ?? this.skinType,
      concerns: concerns ?? this.concerns,
      budget: budget ?? this.budget,
      imagePath: imagePath ?? this.imagePath,
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
  QuizAnswer answer = const QuizAnswer();
  final notesController = TextEditingController();

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (step + 1) / 4;
    return Scaffold(
      appBar: const GlassHeader(currentRoute: AppRoutes.quiz),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionBadge(label: 'Skin Quiz', icon: Icons.quiz_outlined),
                  const SizedBox(height: 14),
                  Text('Build your skin profile in 4 calm steps.', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text('Step ${step + 1} of 4', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                    color: const Color(0xFFC4A882),
                    backgroundColor: const Color(0xFFF5F0E8),
                  ),
                  const SizedBox(height: 24),
                  PremiumCard(child: _buildStep()),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: step == 0 ? () => Navigator.pop(context) : () => setState(() => step -= 1),
                        child: Text(step == 0 ? 'Back Home' : 'Back'),
                      ),
                      const Spacer(),
                      GradientPillButton(
                        label: step == 3 ? 'Continue to Analysis' : 'Next',
                        onPressed: () {
                          if (step == 3) {
                            Navigator.pushNamed(context, AppRoutes.analysis);
                            return;
                          }
                          setState(() => step += 1);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What best describes your skin type?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...MockSkinData.quizSkinTypes.map((type) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SelectableOptionCard(
                    title: type,
                    description: 'Choose the description that feels closest to your daily skin behavior.',
                    selected: answer.skinType == type,
                    icon: Icons.spa_outlined,
                    onTap: () => setState(() => answer = answer.copyWith(skinType: type)),
                  ),
                )),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Which concerns are you noticing most?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...MockSkinData.quizConcerns.map((concern) {
              final selected = answer.concerns.contains(concern);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SelectableOptionCard(
                  title: concern,
                  description: 'Tap to include this concern in your profile.',
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
            }),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What is your skincare budget?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...MockSkinData.budgets.map((budget) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SelectableOptionCard(
                    title: budget,
                    description: 'This helps us prioritize product mixes that feel realistic for you.',
                    selected: answer.budget == budget,
                    icon: Icons.attach_money_rounded,
                    onTap: () => setState(() => answer = answer.copyWith(budget: budget)),
                  ),
                )),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload your skin photo', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE8D5B7)),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 42),
                  const SizedBox(height: 12),
                  Text('Preview upload area', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'TODO: connect image_picker or desktop file picker for a real image selection flow.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const AppTextField(
              label: 'Photo notes',
              hint: 'Optional notes about lighting, irritation, or recent changes.',
              maxLines: 3,
            ),
          ],
        );
    }
  }
}
