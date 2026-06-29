import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_locale.dart';
import '../../core/responsive/responsive.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
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
  static const _skinTypes = [
    'Normal',
    'Oily',
    'Dry',
    'Combination',
    'Sensitive',
  ];
  static const _concerns = [
    'Acne',
    'Dark spots',
    'Dryness',
    'Redness',
    'Large pores',
    'Uneven tone',
  ];
  static const _budgets = ['Tiet kiem', 'Trung binh', 'Cao cap'];

  int step = 0;
  String? selectedSkinType;
  String? selectedBudget;
  final selectedConcerns = <String>{};
  File? selectedImage;

  String _translateType(String type, AppLocale locale) {
    return switch (type) {
      'Normal' => locale.tr('quiz_type_normal'),
      'Oily' => locale.tr('quiz_type_oily'),
      'Dry' => locale.tr('quiz_type_dry'),
      'Combination' => locale.tr('quiz_type_combination'),
      'Sensitive' => locale.tr('quiz_type_sensitive'),
      _ => type,
    };
  }

  String _translateConcern(String concern, AppLocale locale) {
    return switch (concern) {
      'Acne' => locale.tr('quiz_concern_acne'),
      'Dark spots' => locale.tr('quiz_concern_dark_spots'),
      'Dryness' => locale.tr('quiz_concern_dryness'),
      'Redness' => locale.tr('quiz_concern_redness'),
      'Large pores' => locale.tr('quiz_concern_large_pores'),
      'Uneven tone' => locale.tr('quiz_concern_uneven_tone'),
      _ => concern,
    };
  }

  String _translateBudget(String budget, AppLocale locale) {
    return switch (budget) {
      'Tiet kiem' => locale.tr('quiz_budget_tiet_kiem'),
      'Trung binh' => locale.tr('quiz_budget_trung_binh'),
      'Cao cap' => locale.tr('quiz_budget_cao_cap'),
      _ => budget,
    };
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: GlassHeader(
        currentRoute: AppRoutes.quiz,
        title: locale.tr('quiz_title'),
      ),
      body: ResponsiveContainer(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: Responsive.responsivePadding(
                    context,
                    top: 0,
                    bottom: 16,
                  ),
                  child: _buildStep(context),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    Responsive.responsiveHorizontalPadding(context),
                    12,
                    Responsive.responsiveHorizontalPadding(context),
                    8,
                  ),
                  child: Column(
                    children: [
                      if (appState.errorMessage != null) ...[
                        Text(
                          appState.errorMessage!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.error),
                        ),
                        const SizedBox(height: 8),
                      ],
                      GradientPillButton(
                        label: step == 3 ? locale.tr('quiz_save_analyze') : locale.tr('common_continue'),
                        isLoading: appState.isBusy,
                        expanded: true,
                        onPressed: _canContinue()
                            ? () => _handleContinue(appState)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: step == 0
                            ? () => Navigator.of(context).maybePop()
                            : () => setState(() => step -= 1),
                        child: Text(step == 0 ? locale.tr('common_back') : locale.tr('quiz_previous')),
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
    final locale = AppLocale.of(context);
    final titleStyle = Theme.of(context).textTheme.headlineMedium;
    switch (step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locale.tr('quiz_step0_title'), style: titleStyle),
            const SizedBox(height: 16),
            ..._skinTypes.map(
              (type) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SelectableOptionCard(
                  title: _translateType(type, locale),
                  description: locale.tr('quiz_step0_desc'),
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
            Text(locale.tr('quiz_step1_title'), style: titleStyle),
            const SizedBox(height: 16),
            ..._concerns.map(
              (concern) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SelectableOptionCard(
                  title: _translateConcern(concern, locale),
                  description: locale.tr('quiz_step1_desc'),
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
            Text(locale.tr('quiz_step2_title'), style: titleStyle),
            const SizedBox(height: 16),
            ..._budgets.map(
              (budget) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SelectableOptionCard(
                  title: _translateBudget(budget, locale),
                  description: locale.tr('quiz_step2_desc'),
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
            Text(locale.tr('quiz_step3_title'), style: titleStyle),
            const SizedBox(height: 12),
            Text(
              locale.tr('quiz_step3_desc'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: Responsive.isTablet(context) ? 1.5 : 1.0,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.camera_alt_outlined,
                            size: 48,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(height: 12),
                          Text(locale.tr('quiz_step3_placeholder')),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.file(selectedImage!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(locale.tr('upload_camera')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(locale.tr('upload_gallery')),
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
