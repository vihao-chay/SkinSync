import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/section_header.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({
    super.key,
    this.initialCategory,
    this.initialConcern,
    this.initialBudget,
    this.referenceId,
  });

  final String? initialCategory;
  final String? initialConcern;
  final double? initialBudget;
  final String? referenceId;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late final TextEditingController _categoryController;
  late final TextEditingController _concernController;
  late final TextEditingController _budgetController;
  AiProductRecommendResponse? _result;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(
      text: widget.initialCategory ?? 'serum',
    );
    _concernController = TextEditingController(
      text: widget.initialConcern ?? 'acne',
    );
    _budgetController = TextEditingController(
      text: widget.initialBudget?.toStringAsFixed(0) ?? '',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _submit());
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _concernController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final result = await context.read<AppState>().recommendProducts(
        category: _blankToAny(_categoryController.text),
        concern: _blankToAny(_concernController.text),
        budgetMax: double.tryParse(_budgetController.text.trim()),
      );
      if (!mounted) {
        return;
      }
      setState(() => _result = result);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openAddToRoutine(AiRecommendedProduct item) async {
    String selectedRoutine = 'Evening';
    var allowConflicts = false;

    final appState = context.read<AppState>();
    final response = await showModalBottomSheet<AiAddProductToRoutineResponse>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _ActionSheet(
              title: 'Add to routine',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Morning', label: Text('Morning')),
                      ButtonSegment(value: 'Evening', label: Text('Evening')),
                    ],
                    selected: {selectedRoutine},
                    onSelectionChanged: (value) =>
                        setSheetState(() => selectedRoutine = value.first),
                  ),
                  if (allowConflicts) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Conflict override enabled. SkinSync will still add this product if warnings appear.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Add product',
                    onPressed: () async {
                      final result = await appState.addProductToRoutine(
                        productId: item.productId,
                        routineType: selectedRoutine,
                        allowConflicts: allowConflicts,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      if (result.requiresConfirmation &&
                          result.warnings.isNotEmpty &&
                          !allowConflicts) {
                        final proceed = await showModalBottomSheet<bool>(
                          context: context,
                          builder: (context) =>
                              _ConflictWarningSheet(warnings: result.warnings),
                        );
                        if (!context.mounted) {
                          return;
                        }
                        if (proceed == true) {
                          setSheetState(() => allowConflicts = true);
                        }
                        return;
                      }
                      if (context.mounted) {
                        Navigator.pop(context, result);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || response == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Products',
      subtitle:
          'Discover AI-ranked skincare products that fit your concern, budget, and current routine.',
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.bottomNavHeight + 64,
        ),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Refine your search',
                  subtitle: 'Use simple filters, then let SkinSync rank the best matches.',
                ),
                const SizedBox(height: AppSpacing.md),
                _Field(label: 'Category', controller: _categoryController),
                const SizedBox(height: AppSpacing.sm),
                _Field(label: 'Concern', controller: _concernController),
                const SizedBox(height: AppSpacing.sm),
                _Field(
                  label: 'Budget max (optional)',
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Recommend products',
                  icon: const Icon(Icons.search_rounded),
                  isLoading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeader(
            title: 'Recommendations',
            subtitle:
                'Premium skincare suggestions, conflict-aware and ready to add into your routine.',
          ),
          const SizedBox(height: AppSpacing.md),
          if (_loading && _result == null)
            const _LoadingStateCard()
          else if (_result == null)
            EmptyStateCard(
              icon: Icons.shopping_bag_outlined,
              title: 'No recommendations yet',
              description:
                  'SkinSync will surface product matches here after your filters are applied.',
            )
          else if (_result!.products.isEmpty)
            EmptyStateCard(
              icon: Icons.search_off_rounded,
              title: 'No products matched',
              description:
                  'Try a broader category, a different concern, or remove the budget limit for more options.',
            )
          else
            ..._result!.products.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ProductCard(
                  item: item,
                  onAddToRoutine: () => _openAddToRoutine(item),
                  onAskAi: () => Navigator.pushNamed(
                    context,
                    AppRoutes.aiChatConversation,
                    arguments: AiChatLaunchArgs(
                      entryPoint: 'product_detail',
                      referenceId: item.productId,
                      prefillMessage:
                          'Can you explain whether ${item.name} fits my skin and routine?',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _blankToAny(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'any' : trimmed;
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.item,
    required this.onAddToRoutine,
    required this.onAskAi,
  });

  final AiRecommendedProduct item;
  final VoidCallback onAddToRoutine;
  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${_friendlyText(item.brand)} • ${_friendlyText(item.category)}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
              _ScoreBadge(score: item.matchScore),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            item.aiReason.trim().isEmpty ? 'Not provided yet' : item.aiReason,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${item.price.toStringAsFixed(0)} ${item.currency}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (item.warnings.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...item.warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  warning,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Ask AI',
                  variant: AppButtonVariant.secondary,
                  onPressed: onAskAi,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Add to routine',
                  onPressed: onAddToRoutine,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingStateCard extends StatelessWidget {
  const _LoadingStateCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Finding premium matches for your skin profile.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ConflictWarningSheet extends StatelessWidget {
  const _ConflictWarningSheet({required this.warnings});

  final List<AiRoutineConflictWarning> warnings;

  @override
  Widget build(BuildContext context) {
    return _ActionSheet(
      title: 'Potential conflicts detected',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...warnings.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                '${item.productAName} + ${item.productBName}\n${item.message}\nAdvice: ${item.recommendation}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Back to edit',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Proceed anyway',
                  variant: AppButtonVariant.danger,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$score% match',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
    );
  }
}

String _friendlyText(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? 'Not provided yet' : trimmed;
}
