import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass_header.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/selectable_option_card.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  static const _skinTypes = ['Normal', 'Oily', 'Dry', 'Combination', 'Sensitive'];
  static const _concerns = ['Acne', 'Dark spots', 'Dryness', 'Redness', 'Large pores', 'Uneven tone'];
  static const _budgets = ['Tiet kiem', 'Trung binh', 'Cao cap'];

  int step = 0;
  String? selectedSkinType;
  String? selectedBudget;
  final selectedConcerns = <String>{};
  File? selectedImage;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

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
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  child: _buildStep(context),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      if (appState.errorMessage != null) ...[
                        Text(
                          appState.errorMessage!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
                        ),
                        const SizedBox(height: 8),
                      ],
                      GradientPillButton(
                        label: step == 3 ? 'Save And Analyze' : 'Continue',
                        isLoading: appState.isBusy,
                        expanded: true,
                        onPressed: _canContinue() ? () => _handleContinue(appState) : null,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: step == 0 ? () => Navigator.of(context).maybePop() : () => setState(() => step -= 1),
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

  Widget _buildStep(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineMedium;
    switch (step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What best describes your skin type?', style: titleStyle),
            const SizedBox(height: 16),
            ..._skinTypes.map(
              (type) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SelectableOptionCard(
                  title: type,
                  description: 'Used to personalize your AI analysis and routine.',
                  selected: selectedSkinType == type,
                  icon: Icons.spa_outlined,
                  onTap: () => setState(() => selectedSkinType = type),
                ),
              ),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Which concerns matter most?', style: titleStyle),
            const SizedBox(height: 16),
            ..._concerns.map(
              (concern) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SelectableOptionCard(
                  title: concern,
                  description: 'Tap to include this in your profile.',
                  selected: selectedConcerns.contains(concern),
                  icon: Icons.check_circle_outline_rounded,
                  onTap: () => setState(() {
                    if (selectedConcerns.contains(concern)) {
                      selectedConcerns.remove(concern);
                    } else {
                      selectedConcerns.add(concern);
                    }
                  }),
                ),
              ),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What is your skincare budget?', style: titleStyle),
            const SizedBox(height: 16),
            ..._budgets.map(
              (budget) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SelectableOptionCard(
                  title: budget,
                  description: 'This helps match routine recommendations to realistic product tiers.',
                  selected: selectedBudget == budget,
                  icon: Icons.sell_outlined,
                  onTap: () => setState(() => selectedBudget = budget),
                ),
              ),
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload your skin photo', style: titleStyle),
            const SizedBox(height: 12),
            Text(
              'Use bright lighting, face forward, and avoid heavy filters.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: selectedImage == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 48, color: AppColors.primaryDark),
                        SizedBox(height: 12),
                        Text('Select a clear selfie to continue'),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.file(selectedImage!, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  bool _canContinue() {
    return switch (step) {
      0 => selectedSkinType != null,
      1 => selectedConcerns.isNotEmpty,
      2 => selectedBudget != null,
      _ => selectedImage != null,
    };
  }

  Future<void> _handleContinue(AppState appState) async {
    if (step < 3) {
      setState(() => step += 1);
      return;
    }

    await appState.saveSurvey(
      skinType: selectedSkinType!,
      budgetLabel: selectedBudget!,
      concerns: selectedConcerns.toList(),
      imageFile: selectedImage,
    );

    if (!mounted) {
      return;
    }

    Navigator.pushReplacementNamed(context, AppRoutes.analysis);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) {
      return;
    }

    setState(() => selectedImage = File(picked.path));
  }
}
