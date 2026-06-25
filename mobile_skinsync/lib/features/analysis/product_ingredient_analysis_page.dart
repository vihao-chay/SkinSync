import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/main_shell.dart';
import 'widgets/analysis_mode_tabs.dart';

class ProductIngredientAnalysisPage extends StatefulWidget {
  const ProductIngredientAnalysisPage({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  final AnalysisMode selectedMode;
  final ValueChanged<AnalysisMode> onModeChanged;

  @override
  State<ProductIngredientAnalysisPage> createState() =>
      _ProductIngredientAnalysisPageState();
}

class _ProductIngredientAnalysisPageState
    extends State<ProductIngredientAnalysisPage> {
  AiProductRecommendResponse? _result;
  bool _loading = true;
  bool _isGenerating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLatestRecommendations();
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
        _errorMessage =
            context.read<AppState>().errorMessage ??
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
        limitPerCategory: 3,
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
        _errorMessage =
            context.read<AppState>().errorMessage ??
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
    final appState = context.watch<AppState>();
    final result = _result;
    final categories =
        result?.categories.where((item) => item.items.isNotEmpty).toList() ??
        const <AiProductRecommendationCategory>[];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 106),
      children: [
        const _MiniTopBar(),
        const SizedBox(height: 14),
        AnalysisModeTabs(
          selectedMode: widget.selectedMode,
          onChanged: widget.onModeChanged,
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product Recommendation',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Latest saved recommendations from your profile, analysis, routine, and recent check-ins. Generate manually when you want a new AI run.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppButton(
              label: result?.hasRecommendation == true
                  ? 'Generate New'
                  : 'Generate',
              isLoading: _isGenerating,
              onPressed: _isGenerating ? null : _generateRecommendations,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SummaryStrip(
          skinType:
              result?.profileSummary.skinType ??
              _friendlyText(appState.profile?.skinType),
          budget:
              result?.profileSummary.budget ??
              _friendlyText(appState.profile?.budgetLabel),
          concerns:
              result?.profileSummary.concerns ??
              appState.profile?.concerns ??
              const [],
        ),
        if (_isGenerating) ...[
          const SizedBox(height: 12),
          const _InfoCard(
            title: 'Generating recommendations',
            body:
                'Generating product recommendations from your latest skin analysis...',
          ),
        ],
        if (result?.note?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _InfoCard(title: 'Recommendation note', body: result!.note!),
        ],
        const SizedBox(height: 18),
        if (_loading && result == null)
          const _InfoCard(
            title: 'Loading latest recommendations',
            body:
                'SkinSync is loading your most recent saved recommendation session.',
          )
        else if (_errorMessage != null && result == null)
          _InfoCard(
            title: 'Recommendations could not load',
            body: _errorMessage!,
          )
        else if (result?.hasRecommendation != true || categories.isEmpty)
          _InfoCard(
            title: 'No recommendations yet',
            body: result?.message?.trim().isNotEmpty == true
                ? result!.message!
                : 'No recommendations yet. Analyze your skin, then generate product recommendations.',
          )
        else ...[
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CategorySection(category: category),
            ),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Open full Products',
            variant: AppButtonVariant.secondary,
            onPressed: () => MainShell.navigateToTab(
              context,
              AppRoutes.products,
              arguments: const ProductsPageArgs(),
            ),
          ),
        ],
      ],
    );
  }
}

class _MiniTopBar extends StatelessWidget {
  const _MiniTopBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          const BrandLogo(size: 24, radius: 8, showShadow: false),
          const Spacer(),
          Text(
            'SkinSync',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.shopping_bag_outlined,
            size: 17,
            color: AppColors.foreground,
          ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.skinType,
    required this.budget,
    required this.concerns,
  });

  final String skinType;
  final String budget;
  final List<String> concerns;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MiniPill(label: 'Skin type', value: skinType),
        _MiniPill(label: 'Budget', value: budget),
        _MiniPill(label: 'Concerns', value: _concernSummary(concerns)),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category});

  final AiProductRecommendationCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.label.trim().isEmpty
                ? _categoryLabel(category.key)
                : category.label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (category.reason.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              category.reason,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...category.items
              .take(2)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProductCard(item: item),
                ),
              ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item});

  final AiRecommendedProduct item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${item.matchPercent ?? item.matchScore}%',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontFamily: 'PlusJakartaSans',
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${item.brand} • ${item.category}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Text(
            item.whyRecommended?.trim().isNotEmpty == true
                ? item.whyRecommended!
                : item.aiReason,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${item.price.toStringAsFixed(0)} ${item.currency}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedText,
                  height: 1.5,
                ),
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

String _categoryLabel(String key) {
  return switch (key) {
    'cleanser' => 'Cleanser',
    'toner' => 'Toner',
    'serum' => 'Serum',
    'moisturizer' => 'Moisturizer',
    'sunscreen' => 'Sunscreen',
    'treatment' => 'Treatment',
    'mask' => 'Mask',
    _ =>
      key.isEmpty ? 'Products' : '${key[0].toUpperCase()}${key.substring(1)}',
  };
}
