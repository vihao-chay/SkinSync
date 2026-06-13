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
import '../../core/widgets/category_chip_bar.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/error_state_card.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/metric_card.dart';
import '../../core/widgets/product_recommendation_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_chip.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({
    super.key,
    this.initialCategory,
    this.initialConcern,
    this.initialBudget,
    this.referenceId,
    this.showGeneratePrompt = false,
  });

  final String? initialCategory;
  final String? initialConcern;
  final double? initialBudget;
  final String? referenceId;
  final bool showGeneratePrompt;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  AiProductRecommendResponse? _recommendation;
  bool _loading = true;
  bool _isGenerating = false;
  String? _errorMessage;
  late String _selectedCategory;

  static const _tabs = <_CategoryTab>[
    _CategoryTab('cleanser', 'Cleanser', Icons.soap_outlined),
    _CategoryTab('toner', 'Toner', Icons.opacity_outlined),
    _CategoryTab('serum', 'Serum', Icons.auto_awesome_outlined),
    _CategoryTab('moisturizer', 'Moisturizer', Icons.spa_outlined),
    _CategoryTab('sunscreen', 'Sunscreen', Icons.wb_sunny_outlined),
    _CategoryTab('treatment', 'Treatment', Icons.healing_outlined),
    _CategoryTab('mask', 'Mask', Icons.masks_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = _normalizeCategoryKey(widget.initialCategory);
    if (_selectedCategory.isEmpty) {
      _selectedCategory = _tabs.first.key;
    }
    _fetchLatestRecommendations();
  }

  Future<void> _fetchLatestRecommendations() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await context.read<AppState>().getLatestRecommendations();
      if (!mounted) {
        return;
      }
      setState(() {
        _recommendation = _normalizeResponse(result);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = context.read<AppState>().errorMessage ??
            'Could not load your latest saved recommendations right now.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _generateRecommendations() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final result = await context.read<AppState>().generateRecommendations(
        category: widget.initialCategory,
        concern: widget.initialConcern,
        budgetMax: widget.initialBudget,
        limitPerCategory: 5,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _recommendation = _normalizeResponse(result);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = context.read<AppState>().errorMessage ??
            'Could not generate product recommendations right now.';
      });
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  AiProductRecommendResponse _normalizeResponse(AiProductRecommendResponse value) {
    final mappedCategories = _tabs.map((tab) {
      final existing = value.categories.where(
        (category) => category.key.toLowerCase() == tab.key,
      );
      if (existing.isNotEmpty) {
        return existing.first;
      }

      final items = value.products
          .where((item) => _normalizeCategoryKey(item.category) == tab.key)
          .toList();
      return AiProductRecommendationCategory(
        key: tab.key,
        label: tab.label,
        items: items,
      );
    }).toList();

    return AiProductRecommendResponse(
      hasRecommendation: value.hasRecommendation,
      sessionId: value.sessionId,
      sourceAnalysisId: value.sourceAnalysisId,
      expiresAt: value.expiresAt,
      status: value.status,
      summary: value.summary,
      products: value.products.isNotEmpty
          ? value.products
          : mappedCategories.expand((category) => category.items).toList(),
      categories: mappedCategories,
      profileSummary: value.profileSummary,
      message: value.message,
      note: value.note,
      generatedAt: value.generatedAt,
    );
  }

  Future<void> _openAddToRoutine(AiRecommendedProduct item) async {
    String selection = item.alreadyInRoutine ? 'Evening' : 'Morning';
    final appState = context.read<AppState>();

    final didAdd = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _SheetFrame(
          title: 'Add to routine',
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Choose where this product should appear in your regimen.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Morning', label: Text('Morning')),
                      ButtonSegment(value: 'Evening', label: Text('Evening')),
                      ButtonSegment(value: 'Both', label: Text('Both')),
                    ],
                    selected: {selection},
                    onSelectionChanged: (value) =>
                        setSheetState(() => selection = value.first),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Add to routine',
                    onPressed: () async {
                      try {
                        await _submitAddToRoutine(
                          appState: appState,
                          item: item,
                          selection: selection,
                          allowConflicts: false,
                        );
                        if (context.mounted) {
                          Navigator.pop(context, true);
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                appState.errorMessage ??
                                    'Could not add this product right now.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (didAdd != true || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} was added to your routine.')),
    );
    await _fetchLatestRecommendations();
  }

  Future<void> _submitAddToRoutine({
    required AppState appState,
    required AiRecommendedProduct item,
    required String selection,
    required bool allowConflicts,
  }) async {
    final targets = selection == 'Both'
        ? const ['Morning', 'Evening']
        : [selection];

    for (final target in targets) {
      final result = await appState.addProductToRoutine(
        productId: item.productId,
        routineType: target,
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
            item: item,
            selection: target,
            allowConflicts: true,
          );
        }
      }
    }
  }

  Future<void> _viewDetails(AiRecommendedProduct item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _SheetFrame(
          title: 'Product details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ProductRecommendationCard(
                item: item,
                onViewDetails: () {},
                onAddToRoutine: () {},
                onCheckIngredients: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailBlock(
                title: 'Why SkinSync picked this',
                body: item.whyRecommended?.trim().isNotEmpty == true
                    ? item.whyRecommended!
                    : item.aiReason,
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailBlock(
                title: 'How to use',
                body: _friendlyText(item.usageGuide),
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailBlock(
                title: 'Ingredients',
                body: _friendlyText(item.ingredientsText),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _checkIngredients(AiRecommendedProduct item) async {
    final ingredientsText = item.ingredientsText?.trim() ?? '';
    final appState = context.read<AppState>();
    if (ingredientsText.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product does not have ingredient data yet.'),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
        ),
      ),
    );

    try {
      final result = await context.read<AppState>().checkIngredients(
        productName: item.name,
        ingredientsText: ingredientsText,
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return _SheetFrame(
            title: 'Ingredient check',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _DetailBlock(
                  title: 'Overall fit',
                  body: result.overallExplanation,
                ),
                const SizedBox(height: AppSpacing.md),
                _DetailBlock(
                  title: 'Suggested use',
                  body: result.usageSuggestion,
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
          );
        },
      );
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
      }
      final message = appState.errorMessage ??
          'Ingredient check is not available right now.';
      messenger.showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final recommendation = _recommendation;
    final profileSummary = recommendation?.profileSummary;
    final category = recommendation?.categories.firstWhere(
          (item) => item.key == _selectedCategory,
          orElse: () => AiProductRecommendationCategory(
            key: _selectedCategory,
            label: _selectedCategory,
          ),
        ) ??
        AiProductRecommendationCategory(key: _selectedCategory, label: _selectedCategory);
    final hasAnyItems = recommendation?.categories.any((c) => c.items.isNotEmpty) ?? false;

    return AppScaffold(
      title: 'Products',
      subtitle: 'AI-ranked products based on your latest skin analysis.',
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
                  children: [
                    const StatusChip(
                      label: 'Based on latest analysis',
                      icon: Icons.auto_awesome_rounded,
                      tone: StatusChipTone.accent,
                    ),
                    const Spacer(),
                    AppButton(
                      label: recommendation?.hasRecommendation == true
                          ? 'Refresh'
                          : 'Generate',
                      expand: false,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      isLoading: _isGenerating,
                      onPressed: _isGenerating ? null : _generateRecommendations,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cards = [
                      MetricCard(
                        label: 'Skin type',
                        value: profileSummary?.skinType ??
                            _friendlyText(appState.profile?.skinType),
                        icon: Icons.spa_outlined,
                      ),
                      MetricCard(
                        label: 'Concern',
                        value: _concernSummary(
                          profileSummary?.concerns ??
                              appState.profile?.concerns ??
                              const [],
                        ),
                        icon: Icons.psychology_alt_outlined,
                      ),
                      MetricCard(
                        label: 'Last generated',
                        value: recommendation?.generatedAt == null
                            ? 'Not yet'
                            : _formatGeneratedAt(recommendation!.generatedAt!),
                        icon: Icons.history_rounded,
                      ),
                    ];
                    return Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: cards
                          .map(
                            (card) => SizedBox(
                              width: constraints.maxWidth < 360
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - AppSpacing.sm) / 2,
                              child: card,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                if (_isGenerating) ...[
                  const SizedBox(height: AppSpacing.md),
                  const _InlineNotice(
                    message: 'Ranking real products from your database...',
                  ),
                ],
                if (widget.showGeneratePrompt &&
                    recommendation?.hasRecommendation != true &&
                    !_isGenerating) ...[
                  const SizedBox(height: AppSpacing.md),
                  const _InlineNotice(
                    message: 'Your latest skin analysis is ready. Tap Generate to create a saved recommendation session.',
                  ),
                ],
                if (recommendation?.summary?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.md),
                  _InlineNotice(message: recommendation!.summary!),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          if (_loading && recommendation == null)
            const _ProductsLoadingState()
          else if (_errorMessage != null && recommendation == null)
            ErrorStateCard(
              title: 'Recommendations could not load',
              description: _errorMessage!,
              ctaLabel: 'Try again',
              onCta: _fetchLatestRecommendations,
            )
          else if (recommendation == null || recommendation.hasRecommendation == false)
            EmptyStateCard(
              icon: Icons.shopping_bag_outlined,
              title: 'No saved recommendations yet',
              description: recommendation?.message ??
                  'Products only show your latest saved recommendation session here.',
              ctaLabel: appState.latestAnalysis?.canGenerateProducts == true
                  ? 'Generate recommendations'
                  : 'Analyze skin',
              onCta: () {
                if (appState.latestAnalysis?.canGenerateProducts == true) {
                  _generateRecommendations();
                  return;
                }
                Navigator.pushNamed(context, AppRoutes.upload);
              },
            )
          else ...[
            SectionHeader(
              icon: Icons.tune_rounded,
              title: 'Browse by category',
              subtitle: 'Switch between saved recommendation groups without starting a new AI run.',
            ),
            const SizedBox(height: AppSpacing.md),
            CategoryChipBar<_CategoryTab>(
              items: _tabs,
              selected: _tabs.firstWhere((tab) => tab.key == _selectedCategory),
              labelBuilder: (tab) => tab.label,
              iconBuilder: (tab) => tab.icon,
              onSelected: (tab) => setState(() => _selectedCategory = tab.key),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            if (category.reason.trim().isNotEmpty)
              AppCard(
                variant: AppCardVariant.accent,
                child: Text(
                  category.reason,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryDark,
                      ),
                ),
              ),
            if (category.reason.trim().isNotEmpty)
              const SizedBox(height: AppSpacing.md),
            if (category.items.isEmpty)
              EmptyStateCard(
                icon: Icons.inventory_2_outlined,
                title: 'No ${category.label.toLowerCase()} matches yet',
                description: recommendation.message?.trim().isNotEmpty == true
                    ? recommendation.message!
                    : 'Add more eligible products to the catalog or refresh manually when your skin context changes.',
                ctaLabel: 'Generate recommendations',
                onCta: _generateRecommendations,
              )
            else
              ...category.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ProductRecommendationCard(
                    item: item,
                    onViewDetails: () => _viewDetails(item),
                    onAddToRoutine: () => _openAddToRoutine(item),
                    onCheckIngredients: () => _checkIngredients(item),
                  ),
                ),
              ),
            if (!hasAnyItems && recommendation.message?.trim().isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.md),
              EmptyStateCard(
                icon: Icons.inventory_2_outlined,
                title: 'No recommendations yet',
                description: recommendation.message!,
                ctaLabel: 'Generate recommendations',
                onCta: _generateRecommendations,
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatGeneratedAt(DateTime value) {
    final local = value.toLocal();
    final minutes = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} ${local.hour}:$minutes';
  }

  String _concernSummary(List<String> concerns) {
    final cleaned = concerns.where((item) => item.trim().isNotEmpty).take(2).toList();
    return cleaned.isEmpty ? 'Not provided yet' : cleaned.join(', ');
  }
}

class _CategoryTab {
  const _CategoryTab(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;
}

class _ProductsLoadingState extends StatelessWidget {
  const _ProductsLoadingState();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          LoadingSkeleton(width: 160, height: 18),
          SizedBox(height: AppSpacing.md),
          LoadingSkeleton(height: 92, radius: 24),
          SizedBox(height: AppSpacing.sm),
          LoadingSkeleton(height: 92, radius: 24),
          SizedBox(height: AppSpacing.sm),
          LoadingSkeleton(height: 92, radius: 24),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primaryDark,
              height: 1.5,
            ),
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.child,
  });

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
    return _SheetFrame(
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
                      '${warning.productAName} × ${warning.productBName}',
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

String _friendlyText(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? 'Not provided yet' : text;
}

String _normalizeCategoryKey(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  return switch (normalized) {
    'sua rua mat' => 'cleanser',
    'moisturiser' => 'moisturizer',
    'kem duong' => 'moisturizer',
    'kem chong nang' => 'sunscreen',
    'optional' => 'mask',
    _ => normalized,
  };
}
