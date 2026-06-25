import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/product_image.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_chip.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.args});

  final ProductDetailPageArgs args;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  ProductDetail? _detail;
  bool _isLoadingDetail = true;
  bool _isAddingMorning = false;
  bool _isAddingEvening = false;
  bool _isAddingBoth = false;
  bool _isCheckingIngredients = false;
  String? _errorMessage;

  AiRecommendedProduct? get _recommendation => widget.args.recommendationItem;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingDetail = true;
      _errorMessage = null;
    });

    final appState = context.read<AppState>();
    try {
      final detail = await appState.getProductDetail(widget.args.productId);
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail.mergeRecommendation(
          _recommendation,
          alreadyInRoutineOverride: widget.args.alreadyInRoutine,
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage =
            appState.errorMessage ?? 'Could not load this product right now.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetail = false);
      }
    }
  }

  Future<void> _addToRoutine(String selection) async {
    if (!mounted || _detail == null) {
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
    final detail = _detail;
    if (detail == null) {
      return;
    }

    final result = await appState.addProductToRoutine(
      productId: detail.id,
      routineType: selection,
      allowConflicts: allowConflicts,
    );

    if (result.requiresConfirmation &&
        result.warnings.isNotEmpty &&
        !allowConflicts &&
        mounted) {
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        builder: (context) => _ConflictWarningSheet(warnings: result.warnings),
      );
      if (confirmed == true && mounted) {
        await _submitAddToRoutine(
          appState: appState,
          selection: selection,
          allowConflicts: true,
        );
      }
    }
  }

  Future<void> _checkIngredients() async {
    final detail = _detail;
    if (detail == null || !detail.hasIngredientData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ingredient data is not available for this product yet.',
          ),
        ),
      );
      return;
    }

    setState(() => _isCheckingIngredients = true);
    final appState = context.read<AppState>();

    try {
      final result = await appState.checkIngredients(
        productName: detail.name,
        ingredientsText: detail.ingredients.join(', '),
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
              if (result.beneficialIngredients.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _ReasonGroup(
                  title: 'Beneficial ingredients',
                  items: result.beneficialIngredients
                      .map((item) => '${item.ingredient}: ${item.reason}')
                      .toList(),
                ),
              ],
              if (result.cautionIngredients.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _ReasonGroup(
                  title: 'Caution ingredients',
                  items: result.cautionIngredients
                      .map((item) => '${item.ingredient}: ${item.reason}')
                      .toList(),
                ),
              ],
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
              if (result.usageSuggestion.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _DetailBlock(
                  title: 'Recommendation note',
                  body: result.usageSuggestion,
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
    return AppScaffold(
      title: 'Product details',
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
          if (_isLoadingDetail) const _DetailLoadingState(),
          if (!_isLoadingDetail && _errorMessage != null)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product detail could not load',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(_errorMessage!),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(label: 'Try again', onPressed: _loadDetail),
                ],
              ),
            ),
          if (!_isLoadingDetail && _errorMessage == null && _detail != null)
            ..._buildContent(context, _detail!),
        ],
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context, ProductDetail product) {
    final cautions = product.cautions;
    final conflicts = product.conflicts;
    final matchValue = product.matchPercent;

    return [
      AppCard(
        variant: AppCardVariant.hero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductImage(
                  imageUrl: product.imageUrl,
                  width: 118,
                  height: 118,
                  radius: 26,
                  iconSize: 36,
                  placeholderTitle: product.brand.trim().isEmpty
                      ? product.name
                      : product.brand,
                  placeholderSubtitle: product.category,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        product.brand.trim().isEmpty
                            ? 'Brand not provided'
                            : product.brand,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.mutedText),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          StatusChip(
                            label: product.category,
                            icon: Icons.inventory_2_outlined,
                          ),
                          if (matchValue != null)
                            StatusChip(
                              label: '$matchValue% match',
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${product.price.toStringAsFixed(0)} ${product.currency}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (product.description?.trim().isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.md),
              _DetailText(product.description!),
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
              title: 'Why it fits your skin',
              subtitle: 'Saved recommendation context for this product.',
            ),
            const SizedBox(height: AppSpacing.md),
            _DetailText(
              product.whyRecommended?.trim().isNotEmpty == true
                  ? product.whyRecommended!
                  : 'AI explanation is not available for this product yet.',
              muted: product.whyRecommended?.trim().isNotEmpty != true,
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
              title: 'Cautions and conflicts',
              subtitle: 'Only real warnings from current product data.',
            ),
            const SizedBox(height: AppSpacing.md),
            if (cautions.isEmpty && conflicts.isEmpty)
              const _EmptyCopy(
                'No caution or conflict notes are available yet.',
              )
            else ...[
              if (cautions.isNotEmpty)
                _ChipGroup(tone: StatusChipTone.warning, items: cautions),
              if (cautions.isNotEmpty && conflicts.isNotEmpty)
                const SizedBox(height: AppSpacing.sm),
              if (conflicts.isNotEmpty)
                _ChipGroup(
                  tone: StatusChipTone.danger,
                  icon: Icons.error_outline_rounded,
                  items: conflicts,
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
              icon: Icons.science_outlined,
              title: 'Ingredients',
              subtitle: 'Real ingredient data from the product catalog.',
            ),
            const SizedBox(height: AppSpacing.md),
            if (!product.hasIngredientData)
              const _EmptyCopy('Ingredient details are not available yet.')
            else ...[
              _ReasonGroup(
                title: 'Ingredient list',
                items: product.ingredients,
              ),
              if (product.keyIngredients.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _ReasonGroup(
                  title: 'Key ingredients',
                  items: product.keyIngredients,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Check ingredients',
                variant: AppButtonVariant.secondary,
                isLoading: _isCheckingIngredients,
                onPressed: _isCheckingIngredients ? null : _checkIngredients,
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
              subtitle: 'Use-time guidance from the backend product catalog.',
            ),
            const SizedBox(height: AppSpacing.md),
            if (product.usageTime?.trim().isNotEmpty == true)
              StatusChip(
                label: product.usageTime!,
                icon: Icons.wb_twilight_outlined,
                tone: StatusChipTone.accent,
              ),
            if (product.usageTime?.trim().isNotEmpty == true)
              const SizedBox(height: AppSpacing.sm),
            _DetailText(
              product.howToUse?.trim().isNotEmpty == true
                  ? product.howToUse!
                  : 'Usage guidance is not available yet.',
              muted: product.howToUse?.trim().isNotEmpty != true,
            ),
            if (product.skinTypes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _ReasonGroup(title: 'Skin types', items: product.skinTypes),
            ],
            if (product.skinConcerns.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _ReasonGroup(title: 'Skin concerns', items: product.skinConcerns),
            ],
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
              label: product.alreadyInRoutine ? 'Added' : 'Add to Morning',
              isLoading: _isAddingMorning,
              onPressed: _isBusy || product.alreadyInRoutine
                  ? null
                  : () => _addToRoutine('Morning'),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: product.alreadyInRoutine ? 'Added' : 'Add to Evening',
              variant: AppButtonVariant.secondary,
              isLoading: _isAddingEvening,
              onPressed: _isBusy || product.alreadyInRoutine
                  ? null
                  : () => _addToRoutine('Evening'),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: product.alreadyInRoutine ? 'Added' : 'Add to Both',
              variant: AppButtonVariant.secondary,
              isLoading: _isAddingBoth,
              onPressed: _isBusy || product.alreadyInRoutine
                  ? null
                  : () => _addToRoutine('Both'),
            ),
          ],
        ),
      ),
    ];
  }

  bool get _isBusy =>
      _isAddingMorning ||
      _isAddingEvening ||
      _isAddingBoth ||
      _isCheckingIngredients;
}

class _DetailLoadingState extends StatelessWidget {
  const _DetailLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoadingSkeleton(height: 132, radius: 28),
              SizedBox(height: AppSpacing.md),
              LoadingSkeleton(width: 220, height: 18),
              SizedBox(height: AppSpacing.sm),
              LoadingSkeleton(width: 160, height: 14),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sectionGap),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoadingSkeleton(width: 180, height: 18),
              SizedBox(height: AppSpacing.md),
              LoadingSkeleton(height: 84, radius: 22),
            ],
          ),
        ),
      ],
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

class _ReasonGroup extends StatelessWidget {
  const _ReasonGroup({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '- $item',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.items,
    required this.tone,
    this.icon = Icons.warning_amber_rounded,
  });

  final List<String> items;
  final StatusChipTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: items
          .map((item) => StatusChip(label: item, icon: icon, tone: tone))
          .toList(),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
      ],
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
