import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_locale.dart';
import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/responsive/responsive.dart';
import '../../core/services/api_client.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/category_chip_bar.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/error_state_card.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/main_shell.dart';
import '../../core/widgets/product_recommendation_card.dart';
import '../../core/widgets/skin_sync_header.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, ProductsPageArgs? args})
    : args = args ?? const ProductsPageArgs();

  final ProductsPageArgs args;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  AiProductRecommendResponse? _recommendation;
  bool _loading = true;
  bool _isGenerating = false;
  bool _didForwardToRoutine = false;
  int _recommendationRevision = 0;
  String? _errorMessage;
  String? _autoRefreshedAnalysisId;
  late String _selectedCategory;

  static const _tabs = <_CategoryTab>[
    _CategoryTab('all', 'All', Icons.grid_view_rounded),
    _CategoryTab('cleanser', 'Cleanser', Icons.soap_outlined),
    _CategoryTab('toner', 'Toner', Icons.opacity_outlined),
    _CategoryTab('serum', 'Serum', Icons.auto_awesome_outlined),
    _CategoryTab('moisturizer', 'Moisturizer', Icons.spa_outlined),
    _CategoryTab('sunscreen', 'Sunscreen', Icons.wb_sunny_outlined),
    _CategoryTab('treatment', 'Treatment', Icons.healing_outlined),
    _CategoryTab('mask', 'Mask', Icons.masks_outlined),
    _CategoryTab('exfoliant', 'Exfoliant', Icons.blur_circular_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = _normalizeCategoryKey(widget.args.initialCategory);
    if (_selectedCategory.isEmpty) {
      _selectedCategory = _tabs.first.key;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchLatestRecommendations();
      }
    });
  }

  Future<void> _fetchLatestRecommendations() async {
    debugPrint('[SkinSync] latest recommendation read');
    if (!mounted) {
      return;
    }
    final locale = AppLocale.of(context, listen: false);
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final appState = context.read<AppState>();
      final result = await appState.getLatestRecommendations();
      if (!mounted) {
        return;
      }
      final normalized = _normalizeResponse(result);
      setState(() {
        _recommendation = normalized;
        _recommendationRevision += 1;
      });
      if (_shouldRefreshForLatestAnalysis(normalized, appState)) {
        await _refreshForLatestAnalysis(appState);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage =
            context.read<AppState>().errorMessage ??
            locale.tr('products_load_error');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _generateRecommendations() async {
    debugPrint('[SkinSync] manual recommendation generate');
    if (!mounted) {
      return;
    }
    final locale = AppLocale.of(context, listen: false);
    final appState = context.read<AppState>();
    setState(() {
      _isGenerating = true;
      _loading = _recommendation == null;
      _selectedCategory = _tabs.first.key;
      _recommendationRevision += 1;
      _errorMessage = null;
    });

    try {
      final generated = _normalizeResponse(
        await appState.generateRecommendations(
          category: widget.args.initialCategory,
          concern: widget.args.initialConcern,
          budgetMax: widget.args.initialBudget,
          limitPerCategory: 5,
        ),
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _recommendation = generated;
        _loading = false;
        _selectedCategory = _tabs.first.key;
        _recommendationRevision += 1;
      });

      final latest = await _fetchLatestAfterGeneration(
        fallback: generated,
        appState: appState,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _recommendation = latest;
        _recommendationRevision += 1;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = _errorText(
        error,
        appState.errorMessage ?? locale.tr('products_load_error'),
      );
      setState(() {
        _errorMessage = _recommendation == null ? message : null;
      });
      if (_recommendation != null && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _loading = false;
        });
      }
    }
  }

  String _errorText(Object error, String fallback) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    return fallback;
  }

  Future<AiProductRecommendResponse> _fetchLatestAfterGeneration({
    required AiProductRecommendResponse fallback,
    required AppState appState,
  }) async {
    var best = fallback;
    final hasGenerationMarker =
        fallback.sessionId?.trim().isNotEmpty == true ||
        fallback.sourceAnalysisId?.trim().isNotEmpty == true ||
        fallback.generatedAt != null;
    if (!hasGenerationMarker) {
      return fallback;
    }

    for (var attempt = 0; attempt < 5; attempt += 1) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }

      try {
        final latest = _normalizeResponse(
          await appState.getLatestRecommendations(),
        );
        final latestMatchesGeneration =
            !hasGenerationMarker ||
            _matchesGeneratedRecommendation(
              generated: fallback,
              latest: latest,
            );
        if (latestMatchesGeneration) {
          best = latest;
        }
        if (_hasRecommendedProducts(best) && latestMatchesGeneration) {
          break;
        }
      } catch (_) {
        break;
      }
    }

    return best;
  }

  bool _matchesGeneratedRecommendation({
    required AiProductRecommendResponse generated,
    required AiProductRecommendResponse latest,
  }) {
    final generatedSessionId = generated.sessionId?.trim();
    final latestSessionId = latest.sessionId?.trim();
    if (generatedSessionId?.isNotEmpty == true &&
        latestSessionId?.isNotEmpty == true) {
      return latestSessionId == generatedSessionId;
    }

    final generatedSourceAnalysisId = generated.sourceAnalysisId?.trim();
    final latestSourceAnalysisId = latest.sourceAnalysisId?.trim();
    if (generatedSourceAnalysisId?.isNotEmpty == true &&
        latestSourceAnalysisId?.isNotEmpty == true) {
      return latestSourceAnalysisId == generatedSourceAnalysisId;
    }

    final generatedAt = generated.generatedAt;
    final latestAt = latest.generatedAt;
    if (generatedAt != null && latestAt != null) {
      return !latestAt.isBefore(generatedAt);
    }

    return generatedSessionId?.isNotEmpty != true &&
        generatedSourceAnalysisId?.isNotEmpty != true;
  }

  bool _hasRecommendedProducts(AiProductRecommendResponse value) {
    if (value.products.isNotEmpty) {
      return true;
    }
    return value.categories.any((category) => category.items.isNotEmpty);
  }

  bool _shouldRefreshForLatestAnalysis(
    AiProductRecommendResponse recommendation,
    AppState appState,
  ) {
    final analysis = appState.latestAnalysis;
    if (analysis == null) {
      return false;
    }

    final analysisIds = _analysisIds(analysis);
    if (analysisIds.isEmpty) {
      return false;
    }

    final primaryAnalysisId = analysis.id.trim();
    if (_autoRefreshedAnalysisId == primaryAnalysisId) {
      return false;
    }

    final sourceAnalysisId = recommendation.sourceAnalysisId
        ?.trim()
        .toLowerCase();
    return sourceAnalysisId == null || !analysisIds.contains(sourceAnalysisId);
  }

  Set<String> _analysisIds(AnalysisResult analysis) {
    return {
          analysis.id,
          analysis.analysisSessionId,
          analysis.progressEntryId,
          analysis.photoId,
        }
        .whereType<String>()
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  Future<void> _refreshForLatestAnalysis(AppState appState) async {
    final analysis = appState.latestAnalysis;
    final analysisId = analysis?.id.trim();
    if (analysis == null || analysisId == null || analysisId.isEmpty) {
      return;
    }

    _autoRefreshedAnalysisId = analysisId;
    if (mounted) {
      setState(() {
        _isGenerating = true;
        _loading = _recommendation == null;
        _selectedCategory = _tabs.first.key;
        _errorMessage = null;
      });
    }

    try {
      final generated = await appState.refreshRecommendationsForLatestAnalysis(
        category: widget.args.initialCategory,
        concern:
            widget.args.initialConcern ??
            (analysis.issues.isNotEmpty
                ? analysis.issues.first.issueType
                : null),
        budgetMax: widget.args.initialBudget,
        limitPerCategory: 5,
        silent: true,
      );
      if (!mounted || generated == null) {
        return;
      }

      final normalized = _normalizeResponse(generated);
      final latest = await _fetchLatestAfterGeneration(
        fallback: normalized,
        appState: appState,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _recommendation = latest;
        _recommendationRevision += 1;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _loading = false;
        });
      }
    }
  }

  AiProductRecommendResponse _normalizeResponse(
    AiProductRecommendResponse value,
  ) {
    final sourceProducts = value.products.isNotEmpty
        ? value.products
        : value.categories.expand((category) => category.items).toList();
    final mappedCategories = _tabs.map((tab) {
      if (tab.key == 'all') {
        return AiProductRecommendationCategory(
          key: tab.key,
          label: tab.label,
          items: sourceProducts,
        );
      }

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
      products: sourceProducts,
      categories: mappedCategories,
      profileSummary: value.profileSummary,
      message: value.message,
      note: value.note,
      generatedAt: value.generatedAt,
    );
  }

  Future<void> _openAddToRoutine(AiRecommendedProduct item) async {
    if (item.alreadyInRoutine) {
      MainShell.navigateToTab(context, AppRoutes.routine);
      return;
    }

    String selection = 'Morning';
    final appState = context.read<AppState>();
    final locale = AppLocale.of(context);

    final didAdd = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _SheetFrame(
          title: locale.tr('products_add_to_routine'),
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
                    locale.tr('products_choose_regimen_prompt'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RoutineTargetSelector(
                    value: selection,
                    onChanged: (value) =>
                        setSheetState(() => selection = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: locale.tr('products_add_to_routine'),
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
                                    locale.tr('products_error_add_routine'),
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

    debugPrint('[SkinSync] routine add');
    await _fetchLatestRecommendations();

    if (!mounted) {
      return;
    }

    if (widget.args.entryPoint == ProductsEntryPoint.analysisResult &&
        !_didForwardToRoutine) {
      _didForwardToRoutine = true;
      MainShell.navigateToTab(
        context,
        AppRoutes.routine,
        arguments: const RoutinePageArgs(
          entryPoint: RoutineEntryPoint.productAdded,
        ),
      );
      return;
    }

    _showAddedToRoutineSnackBar(item);
  }

  void _showAddedToRoutineSnackBar(AiRecommendedProduct item) {
    final locale = AppLocale.of(context);
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale
                    .tr('products_added_success')
                    .replaceAll('{name}', item.name),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  MainShell.navigateToTab(
                    context,
                    AppRoutes.routine,
                    arguments: const RoutinePageArgs(
                      entryPoint: RoutineEntryPoint.productAdded,
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                label: Text(locale.tr('products_view_routine_action')),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _submitAddToRoutine({
    required AppState appState,
    required AiRecommendedProduct item,
    required String selection,
    required bool allowConflicts,
  }) async {
    final result = await appState.addProductToRoutine(
      productId: item.productId,
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
          item: item,
          selection: selection,
          allowConflicts: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final appState = context.watch<AppState>();
    final recommendation = _recommendation;
    final category =
        recommendation?.categories.firstWhere(
          (item) => item.key == _selectedCategory,
          orElse: () => AiProductRecommendationCategory(
            key: _selectedCategory,
            label: _selectedCategory,
          ),
        ) ??
        AiProductRecommendationCategory(
          key: _selectedCategory,
          label: _selectedCategory,
        );
    final hasAnyItems =
        recommendation?.categories.any((c) => c.items.isNotEmpty) ?? false;
    final contentMaxWidth = Responsive.maxContentWidth(
      context,
      mobile: double.infinity,
      tablet: 760,
      desktop: 1100,
    );
    final horizontalPadding = Responsive.responsiveHorizontalPadding(context);

    return ColoredBox(
      color: AppColors.pageBackground,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: RefreshIndicator(
              color: AppColors.primaryDark,
              onRefresh: _fetchLatestRecommendations,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 0),
                children: [
                  SkinSyncHeader(
                    name: appState.profileDisplayName,
                    avatarUrl: appState.user?.avatarUrl,
                    onAvatarTap: () =>
                        MainShell.navigateToTab(context, AppRoutes.profile),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      Responsive.floatingNavigationBottomSpacing(
                        context,
                        extra: 20,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locale.tr('products_recommended_for_you'),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recommendation?.generatedAt == null
                              ? locale.tr('products_based_on_ai')
                              : locale
                                    .tr('products_based_on_ai_format')
                                    .replaceAll(
                                      '{date}',
                                      _formatGeneratedAt(
                                        recommendation!.generatedAt!,
                                      ),
                                    ),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.foreground),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CategoryChipBar<_CategoryTab>(
                          items: _tabs,
                          selected: _tabs.firstWhere(
                            (tab) => tab.key == _selectedCategory,
                          ),
                          labelBuilder: (tab) => tab.label,
                          onSelected: (tab) =>
                              setState(() => _selectedCategory = tab.key),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Center(
                          child: AppButton(
                            label: locale.tr('products_refresh_all_action'),
                            expand: false,
                            variant: AppButtonVariant.secondary,
                            icon: const Icon(Icons.refresh_rounded),
                            isLoading: _isGenerating,
                            onPressed: _isGenerating
                                ? null
                                : _generateRecommendations,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (_isGenerating)
                          _InlineNotice(
                            message: locale.tr('products_ranking_notice'),
                          ),
                        if (widget.args.showGeneratePrompt &&
                            recommendation?.hasRecommendation != true &&
                            !_isGenerating)
                          _InlineNotice(
                            message: locale.tr(
                              'products_analysis_ready_notice',
                            ),
                          ),
                        if (recommendation?.summary?.trim().isNotEmpty == true)
                          _InlineNotice(message: recommendation!.summary!),
                        if ((_isGenerating ||
                                widget.args.showGeneratePrompt ||
                                recommendation?.summary?.trim().isNotEmpty ==
                                    true) &&
                            !_loading)
                          const SizedBox(height: AppSpacing.md),
                        if (_loading && recommendation == null)
                          const _ProductsLoadingState()
                        else if (_errorMessage != null &&
                            recommendation == null)
                          ErrorStateCard(
                            title: locale.tr('products_load_error'),
                            description: _errorMessage!,
                            ctaLabel: locale.tr('common_retry'),
                            onCta: _fetchLatestRecommendations,
                          )
                        else if (recommendation == null ||
                            recommendation.hasRecommendation == false)
                          EmptyStateCard(
                            icon: Icons.shopping_bag_outlined,
                            title: locale.tr('products_no_saved_yet'),
                            description:
                                recommendation?.message ??
                                locale.tr('products_only_saved_session_desc'),
                            ctaLabel:
                                appState.latestAnalysis?.canGenerateProducts ==
                                    true
                                ? locale.tr('products_generate')
                                : locale.tr('products_analyze_skin_action'),
                            onCta: () {
                              if (appState
                                      .latestAnalysis
                                      ?.canGenerateProducts ==
                                  true) {
                                _generateRecommendations();
                                return;
                              }
                              Navigator.pushNamed(context, AppRoutes.upload);
                            },
                          )
                        else if (category.items.isEmpty)
                          EmptyStateCard(
                            icon: Icons.inventory_2_outlined,
                            title: locale
                                .tr('products_no_matches_yet')
                                .replaceAll(
                                  '{category}',
                                  category.label.toLowerCase(),
                                ),
                            description:
                                recommendation.message?.trim().isNotEmpty ==
                                    true
                                ? recommendation.message!
                                : locale.tr('products_refresh_context_desc'),
                            ctaLabel: locale.tr('products_generate'),
                            onCta: _generateRecommendations,
                          )
                        else ...[
                          if (category.reason.trim().isNotEmpty) ...[
                            AppCard(
                              variant: AppCardVariant.accent,
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                category.reason,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          KeyedSubtree(
                            key: ValueKey(
                              'products_${_recommendationRevision}_${recommendation.sessionId ?? ''}_${recommendation.generatedAt?.millisecondsSinceEpoch ?? 0}_$_selectedCategory',
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final columns = constraints.maxWidth >= 980
                                    ? 3
                                    : constraints.maxWidth >= 640
                                    ? 2
                                    : 1;
                                final itemWidth = columns == 1
                                    ? constraints.maxWidth
                                    : (constraints.maxWidth -
                                              (AppSpacing.md * (columns - 1))) /
                                          columns;
                                return Wrap(
                                  spacing: AppSpacing.md,
                                  runSpacing: AppSpacing.md,
                                  children: category.items
                                      .map(
                                        (item) => SizedBox(
                                          key: ValueKey(
                                            '${_recommendationRevision}_${item.productId}_${item.matchPercent ?? item.matchScore}_${item.alreadyInRoutine}',
                                          ),
                                          width: itemWidth,
                                          child: ProductRecommendationCard(
                                            item: item,
                                            onAddToRoutine: () =>
                                                _openAddToRoutine(item),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                            ),
                          ),
                          if (!hasAnyItems &&
                              recommendation.message?.trim().isNotEmpty == true)
                            EmptyStateCard(
                              icon: Icons.inventory_2_outlined,
                              title: locale
                                  .tr('products_no_matches_yet')
                                  .replaceAll('{category}', ''),
                              description: recommendation.message!,
                              ctaLabel: locale.tr('products_generate'),
                              onCta: _generateRecommendations,
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatGeneratedAt(DateTime value) {
    final local = value.toLocal();
    final minutes = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} ${local.hour}:$minutes';
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

class _RoutineTargetSelector extends StatelessWidget {
  const _RoutineTargetSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final options = ['Morning', 'Evening', 'Both'];
    final labels = {
      'Morning': locale.tr('routine_morning'),
      'Evening': locale.tr('routine_evening'),
      'Both': locale.tr('products_both_routines'),
    };
    return AppCard(
      variant: AppCardVariant.muted,
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            Expanded(
              child: _RoutineTargetButton(
                label: labels[options[i]] ?? options[i],
                selected: value == options[i],
                onTap: () => onChanged(options[i]),
              ),
            ),
            if (i != options.length - 1) const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _RoutineTargetButton extends StatelessWidget {
  const _RoutineTargetButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.large),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.secondary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? AppColors.primaryDark : AppColors.mutedText,
            ),
          ),
        ),
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
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: Colors.white),
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

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});

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
                  color: AppColors.outline,
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
    final locale = AppLocale.of(context);
    return _SheetFrame(
      title: locale.tr('products_conflict_warning_title'),
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
            label: locale.tr('products_add_anyway_action'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }
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
