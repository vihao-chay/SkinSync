import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/brand_logo.dart';
import 'widgets/analysis_mode_tabs.dart';

class ProductIngredientAnalysisPage extends StatelessWidget {
  const ProductIngredientAnalysisPage({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  final AnalysisMode selectedMode;
  final ValueChanged<AnalysisMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile;
    final products = _MockProductCatalog.recommendFor(profile);

    return RefreshIndicator(
      color: AppColors.primaryDark,
      onRefresh: appState.refreshHome,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          6,
          AppSpacing.pagePadding,
          106,
        ),
        children: [
          const _ProductTopBar(),
          const SizedBox(height: 14),
          AnalysisModeTabs(
            selectedMode: selectedMode,
            onChanged: onModeChanged,
          ),
          const SizedBox(height: 18),
          _HeroIntro(profile: profile, productCount: products.length),
          const SizedBox(height: 14),
          _ProfileSnapshot(profile: profile),
          const SizedBox(height: 18),
          _SectionHeader(
            title: 'Recommended products',
            subtitle:
                'Mock catalog matched by ingredient profile and your current skin data.',
          ),
          const SizedBox(height: 12),
          ...products.map(
            (product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProductRecommendationCard(product: product),
            ),
          ),
          const SizedBox(height: 6),
          const _DisclaimerCard(),
        ],
      ),
    );
  }
}

class _ProductTopBar extends StatelessWidget {
  const _ProductTopBar();

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
            Icons.notifications_none_rounded,
            size: 17,
            color: AppColors.foreground,
          ),
        ],
      ),
    );
  }
}

class _HeroIntro extends StatelessWidget {
  const _HeroIntro({required this.profile, required this.productCount});

  final SkinProfile? profile;
  final int productCount;

  @override
  Widget build(BuildContext context) {
    final skinType = _profileSkinType(profile);

    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.spa_outlined,
              color: AppColors.primaryDark,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Products for $skinType skin',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI selected $productCount mock products from a curated skincare catalog based on your profile.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.foreground,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _MiniChip(label: 'Ingredient fit'),
                    _MiniChip(label: 'Routine order'),
                    _MiniChip(label: 'Skin profile match'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSnapshot extends StatelessWidget {
  const _ProfileSnapshot({required this.profile});

  final SkinProfile? profile;

  @override
  Widget build(BuildContext context) {
    final skinType = _cleanValue(profile?.skinType, fallback: 'Not set');
    final concerns = _cleanList(profile?.concerns);
    final avoidList = _cleanList([
      ...?profile?.allergies,
      ...?profile?.avoidIngredients,
    ]);

    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_search_outlined,
                color: AppColors.primaryDark,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Profile used for matching',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _SnapshotTile(label: 'Skin type', value: skinType),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SnapshotTile(
                  label: 'Concerns',
                  value: concerns.isEmpty ? 'None yet' : concerns.join(', '),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SnapshotTile(
            label: 'Avoid list',
            value: avoidList.isEmpty
                ? 'No known avoid ingredients'
                : avoidList.join(', '),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.mutedText,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ProductRecommendationCard extends StatelessWidget {
  const _ProductRecommendationCard({required this.product});

  final _MockProduct product;

  @override
  Widget build(BuildContext context) {
    final verdictColor = product.score >= 88
        ? AppColors.success
        : product.score >= 78
        ? AppColors.warning
        : AppColors.primaryDark;

    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductVisual(product: product),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                        _ScorePill(score: product.score, color: verdictColor),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.brand,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      product.reason,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.foreground,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: product.ingredients
                .map((ingredient) => _IngredientChip(label: ingredient))
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetaTile(
                  icon: Icons.schedule_rounded,
                  label: product.routine,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetaTile(
                  icon: Icons.payments_outlined,
                  label: product.price,
                ),
              ),
            ],
          ),
          if (product.note != null) ...[
            const SizedBox(height: 11),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.14),
                ),
              ),
              child: Text(
                product.note!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryDark,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductVisual extends StatelessWidget {
  const _ProductVisual({required this.product});

  final _MockProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 104,
      decoration: BoxDecoration(
        color: product.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: _ProductPainter(color: product.color, icon: product.icon),
      ),
    );
  }
}

class _ProductPainter extends CustomPainter {
  const _ProductPainter({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = AppColors.primaryDark.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.83),
        width: size.width * 0.54,
        height: size.height * 0.12,
      ),
      shadowPaint,
    );

    final bodyPaint = Paint()..color = color.withValues(alpha: 0.88);
    final capPaint = Paint()..color = AppColors.primaryDark;
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.38)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final bodyRect = Rect.fromLTWH(
      size.width * 0.29,
      size.height * 0.27,
      size.width * 0.42,
      size.height * 0.51,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(8)),
      bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.36,
          size.height * 0.19,
          size.width * 0.28,
          size.height * 0.11,
        ),
        const Radius.circular(5),
      ),
      capPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.39, size.height * 0.35),
      Offset(size.width * 0.39, size.height * 0.65),
      shinePaint,
    );

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: 18,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(
        (size.width - iconPainter.width) / 2,
        size.height * 0.48 - iconPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ProductPainter oldDelegate) {
    return color != oldDelegate.color || icon != oldDelegate.icon;
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$score%',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _IngredientChip extends StatelessWidget {
  const _IngredientChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7F1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.34)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primaryDark,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F2EA),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryDark,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'These are mock product recommendations for UI testing. Real products can be connected to the backend catalog later.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.mutedText,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotTile extends StatelessWidget {
  const _SnapshotTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7F1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primaryDark,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.foreground,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7F1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.34)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primaryDark,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MockProduct {
  const _MockProduct({
    required this.name,
    required this.brand,
    required this.category,
    required this.ingredients,
    required this.reason,
    required this.routine,
    required this.price,
    required this.score,
    required this.color,
    required this.icon,
    this.note,
  });

  final String name;
  final String brand;
  final String category;
  final List<String> ingredients;
  final String reason;
  final String routine;
  final String price;
  final int score;
  final Color color;
  final IconData icon;
  final String? note;
}

class _MockProductCatalog {
  static List<_MockProduct> recommendFor(SkinProfile? profile) {
    final skinType = (profile?.skinType ?? '').toLowerCase();
    final concerns =
        profile?.concerns.map((item) => item.toLowerCase()).toSet() ??
        const <String>{};

    final acneOrOily =
        skinType.contains('oily') ||
        concerns.any((item) => item.contains('acne') || item.contains('oil'));
    final dryOrBarrier =
        skinType.contains('dry') ||
        concerns.any(
          (item) => item.contains('dry') || item.contains('barrier'),
        );
    final sensitive =
        skinType.contains('sensitive') ||
        concerns.any(
          (item) =>
              item.contains('sensitive') ||
              item.contains('redness') ||
              item.contains('irritation'),
        );
    final dullOrPigment = concerns.any(
      (item) =>
          item.contains('dull') ||
          item.contains('pigment') ||
          item.contains('dark') ||
          item.contains('spot'),
    );

    if (sensitive) {
      return const [
        _MockProduct(
          name: 'Cica Reset Milk Cleanser',
          brand: 'Aurelia Lab',
          category: 'Cleanser',
          ingredients: ['Centella', 'Beta-glucan', 'Amino surfactants'],
          reason:
              'Gentle cleanser profile with soothing ingredients and low stripping risk.',
          routine: 'Morning + Evening',
          price: 'Mid range',
          score: 93,
          color: Color(0xFF8FB99C),
          icon: Icons.water_drop_outlined,
        ),
        _MockProduct(
          name: 'Barrier Calm Repair Cream',
          brand: 'DermaKind',
          category: 'Moisturizer',
          ingredients: ['Ceramide NP', 'Panthenol', 'Allantoin'],
          reason: 'Designed around barrier repair and redness-prone comfort.',
          routine: 'Evening',
          price: 'Mid range',
          score: 91,
          color: Color(0xFFD0A86B),
          icon: Icons.spa_outlined,
        ),
        _MockProduct(
          name: 'Soft Shield Mineral SPF 50',
          brand: 'Nude Ray',
          category: 'Sunscreen',
          ingredients: ['Zinc oxide', 'Squalane', 'Vitamin E'],
          reason:
              'Mineral UV filters are often easier for reactive skin to tolerate.',
          routine: 'Morning',
          price: 'Premium',
          score: 88,
          color: Color(0xFFB9A68D),
          icon: Icons.wb_sunny_outlined,
          note: 'Patch test first if your skin reacts to richer textures.',
        ),
      ];
    }

    if (acneOrOily) {
      return const [
        _MockProduct(
          name: 'Pore Balance Gel Cleanser',
          brand: 'SkinDex',
          category: 'Cleanser',
          ingredients: ['Green tea', 'Zinc PCA', 'Amino surfactants'],
          reason:
              'Light gel cleanser that supports oil control without harsh exfoliation.',
          routine: 'Morning + Evening',
          price: 'Budget friendly',
          score: 92,
          color: Color(0xFF79A6A3),
          icon: Icons.bubble_chart_outlined,
        ),
        _MockProduct(
          name: 'Clear Tone Niacinamide 5%',
          brand: 'LumaDerm',
          category: 'Serum',
          ingredients: ['Niacinamide', 'Panthenol', 'Zinc PCA'],
          reason:
              'Matches oily or acne-prone concerns with barrier-friendly oil balance support.',
          routine: 'Morning',
          price: 'Mid range',
          score: 95,
          color: Color(0xFF8D87C9),
          icon: Icons.science_outlined,
        ),
        _MockProduct(
          name: 'Cloud Gel Barrier Moisturizer',
          brand: 'NaturaSync',
          category: 'Moisturizer',
          ingredients: ['Glycerin', 'Betaine', 'Ceramide NP'],
          reason:
              'Hydrates without a heavy finish, useful for oily skin that still needs barrier care.',
          routine: 'Morning + Evening',
          price: 'Mid range',
          score: 89,
          color: Color(0xFF7FAAC8),
          icon: Icons.cloud_outlined,
        ),
        _MockProduct(
          name: 'Matte Veil SPF 50 PA++++',
          brand: 'Daylight Lab',
          category: 'Sunscreen',
          ingredients: ['Modern UV filters', 'Silica', 'Vitamin E'],
          reason:
              'Lightweight finish with oil-control support for daytime wear.',
          routine: 'Morning',
          price: 'Premium',
          score: 86,
          color: Color(0xFFC7A364),
          icon: Icons.wb_sunny_outlined,
        ),
      ];
    }

    if (dryOrBarrier) {
      return const [
        _MockProduct(
          name: 'Comfort Cream Cleanser',
          brand: 'Aurelia Lab',
          category: 'Cleanser',
          ingredients: ['Glycerin', 'Oat extract', 'Amino surfactants'],
          reason:
              'Creamy cleanser format helps reduce tightness after washing.',
          routine: 'Evening',
          price: 'Mid range',
          score: 90,
          color: Color(0xFFC7A97D),
          icon: Icons.water_drop_outlined,
        ),
        _MockProduct(
          name: 'Hydra Cushion Serum',
          brand: 'LumaDerm',
          category: 'Serum',
          ingredients: ['Hyaluronic acid', 'Panthenol', 'Beta-glucan'],
          reason: 'Humectant-rich formula for dehydration and comfort.',
          routine: 'Morning + Evening',
          price: 'Mid range',
          score: 92,
          color: Color(0xFF78AFC8),
          icon: Icons.science_outlined,
        ),
        _MockProduct(
          name: 'Triple Lipid Barrier Cream',
          brand: 'DermaKind',
          category: 'Moisturizer',
          ingredients: ['Ceramide', 'Cholesterol', 'Fatty acids'],
          reason: 'Strong ingredient match for dry skin and barrier support.',
          routine: 'Evening',
          price: 'Premium',
          score: 96,
          color: Color(0xFFB98D68),
          icon: Icons.spa_outlined,
        ),
        _MockProduct(
          name: 'Dew Guard SPF 50',
          brand: 'Nude Ray',
          category: 'Sunscreen',
          ingredients: ['UV filters', 'Squalane', 'Vitamin E'],
          reason:
              'Hydrating sunscreen texture suited for dry morning routines.',
          routine: 'Morning',
          price: 'Premium',
          score: 87,
          color: Color(0xFFD0B275),
          icon: Icons.wb_sunny_outlined,
        ),
      ];
    }

    if (dullOrPigment) {
      return const [
        _MockProduct(
          name: 'Glow Reset Gentle Cleanser',
          brand: 'SkinDex',
          category: 'Cleanser',
          ingredients: ['Glycerin', 'Licorice root', 'Amino surfactants'],
          reason:
              'Keeps cleansing gentle while supporting a brighter-looking routine.',
          routine: 'Morning + Evening',
          price: 'Budget friendly',
          score: 88,
          color: Color(0xFF9CA96A),
          icon: Icons.bubble_chart_outlined,
        ),
        _MockProduct(
          name: 'Tone Bright Vitamin C 8%',
          brand: 'LumaDerm',
          category: 'Serum',
          ingredients: ['Vitamin C', 'Ferulic acid', 'Vitamin E'],
          reason: 'Targets dullness and dark spots with antioxidant support.',
          routine: 'Morning',
          price: 'Premium',
          score: 90,
          color: Color(0xFFD6A04E),
          icon: Icons.auto_awesome_outlined,
          note:
              'Start every other morning if your skin is sensitive to active ingredients.',
        ),
        _MockProduct(
          name: 'Even Tone Night Lotion',
          brand: 'NaturaSync',
          category: 'Moisturizer',
          ingredients: ['Niacinamide', 'Panthenol', 'Ceramide NP'],
          reason: 'Balances tone support with barrier care for nightly use.',
          routine: 'Evening',
          price: 'Mid range',
          score: 91,
          color: Color(0xFF9C87C5),
          icon: Icons.nightlight_outlined,
        ),
      ];
    }

    return const [
      _MockProduct(
        name: 'Gentle Cloud Cleanser',
        brand: 'SkinDex',
        category: 'Cleanser',
        ingredients: ['Glycerin', 'Amino surfactants', 'Panthenol'],
        reason:
            'A balanced cleanser recommendation for maintaining skin comfort.',
        routine: 'Morning + Evening',
        price: 'Budget friendly',
        score: 88,
        color: Color(0xFF88A9A3),
        icon: Icons.bubble_chart_outlined,
      ),
      _MockProduct(
        name: 'Balance Niacinamide Serum',
        brand: 'LumaDerm',
        category: 'Serum',
        ingredients: ['Niacinamide', 'Zinc PCA', 'Panthenol'],
        reason: 'Flexible support for oil balance, pores, and barrier comfort.',
        routine: 'Morning',
        price: 'Mid range',
        score: 90,
        color: Color(0xFF8D87C9),
        icon: Icons.science_outlined,
      ),
      _MockProduct(
        name: 'Barrier Comfort Cream',
        brand: 'DermaKind',
        category: 'Moisturizer',
        ingredients: ['Ceramide NP', 'Squalane', 'Allantoin'],
        reason:
            'A dependable moisturizer pick for keeping your routine stable.',
        routine: 'Evening',
        price: 'Mid range',
        score: 89,
        color: Color(0xFFB98D68),
        icon: Icons.spa_outlined,
      ),
      _MockProduct(
        name: 'Daily Veil SPF 50',
        brand: 'Daylight Lab',
        category: 'Sunscreen',
        ingredients: ['UV filters', 'Vitamin E', 'Silica'],
        reason:
            'Daily sunscreen recommendation to protect progress and reduce irritation triggers.',
        routine: 'Morning',
        price: 'Premium',
        score: 87,
        color: Color(0xFFC7A364),
        icon: Icons.wb_sunny_outlined,
      ),
    ];
  }
}

String _profileSkinType(SkinProfile? profile) {
  final skinType = profile?.skinType?.trim();
  if (skinType == null || skinType.isEmpty) {
    return 'your';
  }
  return skinType;
}

String _cleanValue(String? value, {required String fallback}) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? fallback : trimmed;
}

List<String> _cleanList(Iterable<String>? values) {
  return (values ?? const <String>[])
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}
