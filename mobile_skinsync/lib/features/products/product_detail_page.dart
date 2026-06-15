import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_chip.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.args});

  final ProductDetailPageArgs args;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _isAddingMorning = false;
  bool _isAddingEvening = false;
  bool _isAddingBoth = false;
  bool _isCheckingIngredients = false;

  AiRecommendedProduct get _product => widget.args.product;

  Future<void> _addToRoutine(String selection) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isAddingMorning = selection == 'Morning';
      _isAddingEvening = selection == 'Evening';
      _isAddingBoth = selection == 'Both';
    });

    final appState = context.read<AppState>();

    try {
      await _submitAddToRoutine(
        appState: appState,
        selection: selection,
        allowConflicts: false,
      );
      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        const ProductDetailActionResult(addedToRoutine: true),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appState.errorMessage ?? 'Could not add this product right now.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingMorning = false;
          _isAddingEvening = false;
          _isAddingBoth = false;
        });
      }
    }
  }

  Future<void> _submitAddToRoutine({
    required AppState appState,
    required String selection,
    required bool allowConflicts,
  }) async {
    final targets = selection == 'Both'
        ? const ['Morning', 'Evening']
        : [selection];

    for (final target in targets) {
      final result = await appState.addProductToRoutine(
        productId: _product.productId,
        routineType: target,
        allowConflicts: allowConflicts,
      );

      if (result.requiresConfirmation &&
          result.warnings.isNotEmpty &&
          !allowConflicts &&
          mounted) {
        final confirmed = await showModalBottomSheet<bool>(
          context: context,
          builder: (context) =>
              _ConflictWarningSheet(warnings: result.warnings),
        );
        if (confirmed == true && mounted) {
          await _submitAddToRoutine(
            appState: appState,
            selection: target,
            allowConflicts: true,
          );
        }
      }
    }
  }

  Future<void> _checkIngredients() async {
    final ingredientsText = _product.ingredientsText?.trim() ?? '';
    if (ingredientsText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product does not have ingredient data yet.'),
        ),
      );
      return;
    }

    setState(() => _isCheckingIngredients = true);
    final appState = context.read<AppState>();

    try {
      final result = await appState.checkIngredients(
        productName: _product.name,
        ingredientsText: ingredientsText,
      );
      if (!mounted) {
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _BottomSheetFrame(
          title: 'Ingredient check',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                result.overallExplanation,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                result.usageSuggestion,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
              ),
              if (result.warnings.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: result.warnings
                      .map(
                        (warning) => StatusChip(
                          label: warning,
                          icon: Icons.warning_amber_rounded,
                          tone: StatusChipTone.warning,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appState.errorMessage ??
                'Ingredient check is not available right now.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingIngredients = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    return AppScaffold(
      title: product.name,
      subtitle: 'Why this product fits your skin and how to use it.',
      compactHeader: true,
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.pageBottomPaddingWithActions,
        ),
        children: [
          AppCard(
            variant: AppCardVariant.hero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProductImage(product: product),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              StatusChip(
                                label: product.category,
                                icon: Icons.inventory_2_outlined,
                              ),
                              StatusChip(
                                label:
                                    '${product.matchPercent ?? product.matchScore}% match',
                                icon: Icons.auto_awesome_rounded,
                                tone: StatusChipTone.accent,
                              ),
                              if (product.alreadyInRoutine)
                                const StatusChip(
                                  label: 'Already in routine',
                                  icon: Icons.check_circle_outline_rounded,
                                  tone: StatusChipTone.success,
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            product.brand.trim().isEmpty
                                ? 'Brand not provided'
                                : product.brand,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${product.price.toStringAsFixed(0)} ${product.currency}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontFamily: 'PlusJakartaSans',
                                  fontWeight: FontWeight.w800,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (product.description?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    product.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  icon: Icons.psychology_alt_outlined,
                  title: 'AI explanation',
                  subtitle:
                      'Real recommendation context from the saved session.',
                ),
                const SizedBox(height: AppSpacing.md),
                _DetailText(
                  product.whyRecommended?.trim().isNotEmpty == true
                      ? product.whyRecommended!
                      : product.aiReason,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  icon: Icons.warning_amber_rounded,
                  title: 'Cautions',
                  subtitle: 'Only show warnings that exist for this product.',
                ),
                const SizedBox(height: AppSpacing.md),
                if (product.cautions.isEmpty && product.warnings.isEmpty)
                  const _EmptyCopy(
                    'No caution or conflict notes were provided yet.',
                  )
                else
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children:
                        (product.cautions.isNotEmpty
                                ? product.cautions
                                : product.warnings)
                            .map(
                              (warning) => StatusChip(
                                label: warning,
                                icon: Icons.warning_amber_rounded,
                                tone: StatusChipTone.warning,
                              ),
                            )
                            .toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  icon: Icons.science_outlined,
                  title: 'Ingredients',
                  subtitle:
                      'Use the real product ingredient list when available.',
                ),
                const SizedBox(height: AppSpacing.md),
                if (product.ingredientsText?.trim().isNotEmpty != true)
                  const _EmptyCopy(
                    'Ingredient details are not available for this product yet.',
                  )
                else ...[
                  _DetailText(product.ingredientsText!),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Check ingredients',
                    variant: AppButtonVariant.secondary,
                    isLoading: _isCheckingIngredients,
                    onPressed: _isCheckingIngredients
                        ? null
                        : _checkIngredients,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  icon: Icons.schedule_outlined,
                  title: 'How to use',
                  subtitle:
                      'Backend-provided guidance for cadence and routine placement.',
                ),
                const SizedBox(height: AppSpacing.md),
                _DetailText(
                  product.usageGuide?.trim().isNotEmpty == true
                      ? product.usageGuide!
                      : 'Usage guidance has not been provided yet.',
                  muted: product.usageGuide?.trim().isNotEmpty != true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppCard(
            variant: AppCardVariant.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  icon: Icons.playlist_add_check_circle_outlined,
                  title: 'Add to routine',
                  subtitle: 'Choose exactly where this product should appear.',
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Add to Morning',
                  isLoading: _isAddingMorning,
                  onPressed: _isBusy ? null : () => _addToRoutine('Morning'),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Add to Evening',
                  variant: AppButtonVariant.secondary,
                  isLoading: _isAddingEvening,
                  onPressed: _isBusy ? null : () => _addToRoutine('Evening'),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Add to Both',
                  variant: AppButtonVariant.secondary,
                  isLoading: _isAddingBoth,
                  onPressed: _isBusy ? null : () => _addToRoutine('Both'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _isBusy =>
      _isAddingMorning ||
      _isAddingEvening ||
      _isAddingBoth ||
      _isCheckingIngredients;
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final AiRecommendedProduct product;

  @override
  Widget build(BuildContext context) {
    final raw = product.imageUrl?.trim() ?? '';
    final url = raw.isEmpty
        ? ''
        : (raw.startsWith('http') ? raw : '${AppConfig.apiBaseUrl}$raw');

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 112,
        height: 112,
        color: AppColors.surfaceStrong,
        child: url.isEmpty
            ? const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.primaryDark,
                size: 34,
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.primaryDark,
                  size: 34,
                ),
              ),
      ),
    );
  }
}

class _DetailText extends StatelessWidget {
  const _DetailText(this.text, {this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: muted ? AppColors.mutedText : null,
        height: 1.5,
      ),
    );
  }
}

class _EmptyCopy extends StatelessWidget {
  const _EmptyCopy(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText, height: 1.5),
    );
  }
}

class _BottomSheetFrame extends StatelessWidget {
  const _BottomSheetFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: AppSpacing.lg),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ConflictWarningSheet extends StatelessWidget {
  const _ConflictWarningSheet({required this.warnings});

  final List<AiRoutineConflictWarning> warnings;

  @override
  Widget build(BuildContext context) {
    return _BottomSheetFrame(
      title: 'Check routine conflicts',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...warnings.map(
            (warning) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                variant: AppCardVariant.metric,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${warning.productAName} x ${warning.productBName}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(warning.message),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      warning.recommendation,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AppButton(
            label: 'Add anyway',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }
}
