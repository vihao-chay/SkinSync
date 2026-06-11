import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_header.dart';

class AiProductRecommendPage extends StatefulWidget {
  const AiProductRecommendPage({super.key});

  @override
  State<AiProductRecommendPage> createState() => _AiProductRecommendPageState();
}

class _AiProductRecommendPageState extends State<AiProductRecommendPage> {
  final _categoryController = TextEditingController(text: 'serum');
  final _concernController = TextEditingController(text: 'acne');
  final _budgetController = TextEditingController();
  AiProductRecommendResponse? _result;
  bool _loading = false;

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
        category: _categoryController.text.trim().isEmpty
            ? 'any'
            : _categoryController.text.trim(),
        concern: _concernController.text.trim().isEmpty
            ? 'any'
            : _concernController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const GlassHeader(
        currentRoute: '/ai/product-recommend',
        title: 'Product Match',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _Field(label: 'Category', controller: _categoryController),
          const SizedBox(height: 12),
          _Field(label: 'Concern', controller: _concernController),
          const SizedBox(height: 12),
          _Field(
            label: 'Budget max (optional)',
            controller: _budgetController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: Text(_loading ? 'Loading...' : 'Recommend products'),
          ),
          const SizedBox(height: 18),
          if (_result == null)
            const _HintCard(
              title: 'Real catalog recommendations',
              body:
                  'This page now calls `/api/ai/products/recommend` and renders product cards from backend data instead of mock content.',
            )
          else if (_result!.products.isEmpty)
            const _HintCard(
              title: 'No products matched',
              body:
                  'Try a broader category, a different concern, or remove the budget limit.',
            )
          else
            ..._result!.products.map(
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _ScoreBadge(score: item.matchScore),
            ],
          ),
          const SizedBox(height: 4),
          Text('${item.brand} • ${item.category}'),
          const SizedBox(height: 8),
          Text(item.aiReason),
          const SizedBox(height: 8),
          Text('${item.price.toStringAsFixed(0)} ${item.currency}'),
          if (item.warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...item.warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  warning,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.warning),
                ),
              ),
            ),
          ],
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$score% match'),
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
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.title, required this.body});

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
