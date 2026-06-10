import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_header.dart';

class AiIngredientCheckPage extends StatefulWidget {
  const AiIngredientCheckPage({super.key});

  @override
  State<AiIngredientCheckPage> createState() => _AiIngredientCheckPageState();
}

class _AiIngredientCheckPageState extends State<AiIngredientCheckPage> {
  final _nameController = TextEditingController();
  final _ingredientsController = TextEditingController();
  AiIngredientCheckResponse? _result;
  AiSavedProduct? _savedProduct;
  bool _loading = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final result = await context.read<AppState>().checkIngredients(
        productName: _nameController.text.trim(),
        ingredientsText: _ingredientsController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
        _savedProduct = null;
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveProduct() async {
    if (_saving) {
      return;
    }

    setState(() => _saving = true);
    try {
      final saved = await context.read<AppState>().saveIngredientProduct(
        productName: _nameController.text.trim().isEmpty
            ? 'My Ingredient Product'
            : _nameController.text.trim(),
        ingredientsText: _ingredientsController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() => _savedProduct = saved);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved as My Product.')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _addSavedProductToRoutine() async {
    final product = _savedProduct;
    if (product == null) {
      return;
    }

    final result = await context.read<AppState>().addProductToRoutine(
      productId: product.productId,
      routineType: 'Evening',
    );

    if (!mounted) {
      return;
    }

    if (result.requiresConfirmation && result.warnings.isNotEmpty) {
      final proceed = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => _IngredientConflictSheet(warnings: result.warnings),
      );
      if (proceed == true) {
        final confirmed = await context.read<AppState>().addProductToRoutine(
          productId: product.productId,
          routineType: 'Evening',
          allowConflicts: true,
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(confirmed.message)));
        }
      }
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const GlassHeader(
        currentRoute: '/ai/ingredient-check',
        title: 'Ingredient Check',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Product name',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ingredientsController,
            minLines: 6,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Ingredients',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _ingredientsController.text =
                        'Water, Glycerin, Niacinamide, Panthenol';
                  },
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: const Text('Scan / OCR'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: Text(_loading ? 'Checking...' : 'Check ingredients'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_result != null) ...[
            _SectionCard(
              title: 'Suitability: ${_result!.suitability}',
              child: Text(_result!.overallExplanation),
            ),
            const SizedBox(height: 12),
            _ReasonCard(
              title: 'Beneficial',
              items: _result!.beneficialIngredients,
            ),
            const SizedBox(height: 12),
            _ReasonCard(title: 'Caution', items: _result!.cautionIngredients),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Usage suggestion',
              child: Text(_result!.usageSuggestion),
            ),
            if (_result!.warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Warnings',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _result!.warnings
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(item),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _saveProduct,
                    child: Text(
                      _saving
                          ? 'Saving...'
                          : _savedProduct == null
                          ? 'Save as My Product'
                          : 'Saved',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _savedProduct == null
                        ? null
                        : _addSavedProductToRoutine,
                    child: const Text('Add to Routine'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.aiChatConversation,
                arguments: AiChatLaunchArgs(
                  entryPoint: 'ingredient_result',
                  referenceId: _savedProduct?.productId,
                  prefillMessage:
                      'Can you explain whether this ingredient list is safe for my skin?',
                ),
              ),
              child: const Text('Ask SkinSync AI'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.title, required this.items});

  final String title;
  final List<AiIngredientReason> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      child: items.isEmpty
          ? const Text('No items returned.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('${item.ingredient}: ${item.reason}'),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _IngredientConflictSheet extends StatelessWidget {
  const _IngredientConflictSheet({required this.warnings});

  final List<AiRoutineConflictWarning> warnings;

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
              'Potential conflicts',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '${warning.productAName} + ${warning.productBName}\n${warning.message}\nAdvice: ${warning.recommendation}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Proceed'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
