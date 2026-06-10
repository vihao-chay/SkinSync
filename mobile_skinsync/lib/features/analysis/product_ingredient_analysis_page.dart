import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
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
  final _categoryController = TextEditingController(text: 'serum');
  final _concernController = TextEditingController(text: 'acne');
  AiProductRecommendResponse? _result;
  bool _loading = false;

  @override
  void dispose() {
    _categoryController.dispose();
    _concernController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final result = await context.read<AppState>().recommendProducts(
        category: _categoryController.text.trim(),
        concern: _concernController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
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
        Text(
          'Product Recommendation',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _categoryController,
          decoration: const InputDecoration(
            labelText: 'Category',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _concernController,
          decoration: const InputDecoration(
            labelText: 'Concern',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: Text(_loading ? 'Loading...' : 'Recommend products'),
        ),
        const SizedBox(height: 18),
        if (_result == null)
          const _InfoCard(
            title: 'Backend-powered recommendations',
            body: 'The old mock catalog has been removed. This tab now renders product cards from `/api/ai/products/recommend`.',
          )
        else if (_result!.products.isEmpty)
          const _InfoCard(
            title: 'No matches yet',
            body: 'Try a broader category or change the concern keyword.',
          )
        else
          ..._result!.products.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProductCard(item: item),
            ),
          ),
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item});

  final AiRecommendedProduct item;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text('${item.matchScore}%'),
            ],
          ),
          const SizedBox(height: 6),
          Text('${item.brand} • ${item.category}'),
          const SizedBox(height: 8),
          Text(item.aiReason),
          const SizedBox(height: 8),
          Text('${item.price.toStringAsFixed(0)} ${item.currency}'),
          if (item.warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...item.warnings.map(
              (warning) => Text(
                warning,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
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
          Text(body),
        ],
      ),
    );
  }
}
