import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
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
  bool _loading = false;

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
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: Text(_loading ? 'Checking...' : 'Check ingredients'),
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
