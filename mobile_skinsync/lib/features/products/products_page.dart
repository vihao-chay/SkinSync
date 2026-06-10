import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _submit();
    });
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

  Future<void> _openAddToRoutine(AiRecommendedProduct item) async {
    String selectedRoutine = 'Evening';
    var allowConflicts = false;

    final appState = context.read<AppState>();
    final response = await showModalBottomSheet<AiAddProductToRoutineResponse>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _ActionSheet(
              title: 'Add to Routine',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Morning', label: Text('Morning')),
                      ButtonSegment(value: 'Evening', label: Text('Evening')),
                    ],
                    selected: {selectedRoutine},
                    onSelectionChanged: (value) =>
                        setSheetState(() => selectedRoutine = value.first),
                  ),
                  const SizedBox(height: 12),
                  if (allowConflicts)
                    Text(
                      'Conflict override enabled. The product will still be added if warnings appear.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final result = await appState.addProductToRoutine(
                          productId: item.productId,
                          routineType: selectedRoutine,
                          allowConflicts: allowConflicts,
                        );
                        if (!mounted) {
                          return;
                        }
                        if (result.requiresConfirmation &&
                            result.warnings.isNotEmpty &&
                            !allowConflicts) {
                          final proceed = await showModalBottomSheet<bool>(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) =>
                                _ConflictWarningSheet(warnings: result.warnings),
                          );
                          if (proceed == true) {
                            setSheetState(() => allowConflicts = true);
                          }
                          return;
                        }
                        if (context.mounted) {
                          Navigator.pop(context, result);
                        }
                      },
                      child: const Text('Add product'),
                    ),
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
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Text(
              'Products',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Filter by concern and budget, then add matched products into your routine with conflict review.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
            ),
            const SizedBox(height: 18),
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
            if (_loading && _result == null)
              const _HintCard(
                title: 'Finding product matches',
                body:
                    'SkinSync is ranking products from your backend catalog based on concern, budget, and profile fit.',
              )
            else if (_result == null)
              const _HintCard(
                title: 'Real catalog recommendations',
                body:
                    'Use filters to load AI-ranked products from your backend catalog. Then add them into your routine with conflict review.',
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
      ),
    );
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
      ),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${item.brand} - ${item.category}'),
                  ],
                ),
              ),
              _ScoreBadge(score: item.matchScore),
            ],
          ),
          const SizedBox(height: 10),
          Text(item.aiReason),
          const SizedBox(height: 10),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onAskAi,
                  child: const Text('Ask AI'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onAddToRoutine,
                  child: const Text('Add to Routine'),
                ),
              ),
            ],
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...warnings.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${item.productAName} + ${item.productBName}\n${item.message}\nAdvice: ${item.recommendation}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.foreground,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Back to edit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Proceed anyway'),
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
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
