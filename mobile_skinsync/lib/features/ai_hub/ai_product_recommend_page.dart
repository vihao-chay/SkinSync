import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/error_state_card.dart';
import '../../core/widgets/glass_header.dart';

class AiProductRecommendPage extends StatefulWidget {
  const AiProductRecommendPage({super.key});

  @override
  State<AiProductRecommendPage> createState() => _AiProductRecommendPageState();
}

class _AiProductRecommendPageState extends State<AiProductRecommendPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  AiProductRecommendResponse? _result;
  String? _errorMessage;
  bool _loading = true;
  bool _isGenerating = false;

  static const _fallbackTabs = <String>[
    'cleanser',
    'toner',
    'serum',
    'moisturizer',
    'sunscreen',
    'treatment',
    'mask',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _fallbackTabs.length, vsync: this);
    _loadLatestRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestRecommendations() async {
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
        _result = result;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = context.read<AppState>().errorMessage ??
            'Could not load the latest saved product recommendations right now.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _generateRecommendations() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final result = await context.read<AppState>().generateRecommendations(
        limitPerCategory: 5,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
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

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final categories = _visibleCategories(result);
    final tabs = _fallbackTabs
        .map(
          (key) => categories.firstWhere(
            (category) => category.key.toLowerCase() == key,
            orElse: () => AiProductRecommendationCategory(
              key: key,
              label: _labelForCategory(key),
            ),
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const GlassHeader(
        currentRoute: '/ai/product-recommend',
        title: 'Product Match',
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  12,
                  AppSpacing.pagePadding,
                  AppSpacing.pageBottomPaddingWithActions,
                ),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI recommendations',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'This screen only shows your latest saved recommendation session until you manually generate a new one.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppColors.mutedText),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            AppButton(
                              label: result?.hasRecommendation == true
                                  ? 'Generate New'
                                  : 'Generate',
                              isLoading: _isGenerating,
                              icon: const Icon(Icons.auto_awesome_rounded),
                              onPressed: _isGenerating ? null : _generateRecommendations,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            _MiniPill(
                              label: 'Skin type',
                              value: result?.profileSummary.skinType ??
                                  _friendlyText(
                                    context.read<AppState>().profile?.skinType,
                                  ),
                            ),
                            _MiniPill(
                              label: 'Budget',
                              value: result?.profileSummary.budget ??
                                  _friendlyText(
                                    context.read<AppState>().profile?.budgetLabel,
                                  ),
                            ),
                            _MiniPill(
                              label: 'Concerns',
                              value: _concernSummary(
                                result?.profileSummary.concerns ??
                                    context.read<AppState>().profile?.concerns ??
                                    const [],
                              ),
                            ),
                          ],
                        ),
                        if (_isGenerating) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Generating product recommendations from your latest skin analysis...',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primaryDark,
                                  height: 1.5,
                                ),
                          ),
                        ],
                        if (result?.note?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            result!.note!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primaryDark,
                                  height: 1.5,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  if (_loading && result == null)
                    const _LoadingCard()
                  else if (_errorMessage != null && result == null)
                    ErrorStateCard(
                      title: 'Recommendations could not load',
                      description: _errorMessage!,
                      ctaLabel: 'Try again',
                      onCta: _loadLatestRecommendations,
                    )
                  else if (result?.hasRecommendation != true ||
                      tabs.isEmpty ||
                      tabs.every((category) => category.items.isEmpty))
                    EmptyStateCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'No recommendations yet',
                      description: result?.message?.trim().isNotEmpty == true
                          ? result!.message!
                          : 'No recommendations yet. Analyze your skin, then generate product recommendations.',
                      ctaLabel: 'Generate recommendations',
                      onCta: _generateRecommendations,
                    )
                  else ...[
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.76),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: AppColors.primaryDark,
                        unselectedLabelColor: AppColors.mutedText,
                        indicatorColor: AppColors.primaryDark,
                        labelStyle: Theme.of(context).textTheme.labelLarge,
                        tabs: tabs.map((tab) => Tab(text: tab.label)).toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 520,
                      child: TabBarView(
                        controller: _tabController,
                        children: tabs
                            .map(
                              (category) => ListView.separated(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 8),
                                itemCount: category.items.length + 1,
                                separatorBuilder: (_, index) =>
                                    const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return AppCard(
                                      backgroundColor: AppColors.surfaceStrong,
                                      child: Text(
                                        category.reason.trim().isNotEmpty
                                            ? category.reason
                                            : 'Premium ${category.label.toLowerCase()} picks chosen from the verified SkinSync catalog.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.primaryDark,
                                              height: 1.5,
                                            ),
                                      ),
                                    );
                                  }

                                  final item = category.items[index - 1];
                                  return _RecommendationCard(item: item);
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AiProductRecommendationCategory> _visibleCategories(
    AiProductRecommendResponse? result,
  ) {
    if (result == null) {
      return const [];
    }
    if (result.categories.isNotEmpty) {
      return result.categories;
    }

    final grouped = <String, List<AiRecommendedProduct>>{};
    for (final item in result.products) {
      final key = item.category.trim().toLowerCase();
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return grouped.entries
        .map(
          (entry) => AiProductRecommendationCategory(
            key: entry.key,
            label: _labelForCategory(entry.key),
            items: entry.value,
          ),
        )
        .toList();
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item});

  final AiRecommendedProduct item;

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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${item.brand} • ${item.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${item.matchPercent ?? item.matchScore}% match',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primaryDark,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.whyRecommended?.trim().isNotEmpty == true
                ? item.whyRecommended!
                : item.aiReason,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${item.price.toStringAsFixed(0)} ${item.currency}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          if (item.cautions.isNotEmpty || item.warnings.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...((item.cautions.isNotEmpty ? item.cautions : item.warnings)
                .take(2)
                .map(
                  (warning) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      warning,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                          ),
                    ),
                  ),
                )),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Open full Products',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.products),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primaryDark,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

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
            'Finding products that fit your skin...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

String _friendlyText(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? 'Not provided yet' : trimmed;
}

String _concernSummary(List<String> values) {
  final cleaned = values.where((item) => item.trim().isNotEmpty).toList();
  if (cleaned.isEmpty) {
    return 'Not provided yet';
  }
  if (cleaned.length == 1) {
    return cleaned.first;
  }
  return '${cleaned.first} +${cleaned.length - 1}';
}

String _labelForCategory(String key) {
  return switch (key) {
    'cleanser' => 'Cleanser',
    'toner' => 'Toner',
    'serum' => 'Serum',
    'moisturizer' => 'Moisturizer',
    'sunscreen' => 'Sunscreen',
    'treatment' => 'Treatment',
    'mask' => 'Mask',
    _ => key.isEmpty ? 'Products' : '${key[0].toUpperCase()}${key.substring(1)}',
  };
}
