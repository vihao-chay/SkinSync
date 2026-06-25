import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class SubscriptionSuccessPage extends StatelessWidget {
  const SubscriptionSuccessPage({
    super.key,
    required this.plan,
    required this.orderCode,
    this.renewalDate,
  });

  final SubscriptionPlan plan;
  final int orderCode;
  final DateTime? renewalDate;

  @override
  Widget build(BuildContext context) {
    final enabledFeatures = plan.features
        .where(
          (feature) =>
              feature.isEnabled &&
              (feature.isUnlimited ||
                  feature.monthlyLimit == null ||
                  feature.monthlyLimit! > 0),
        )
        .take(4)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pagePadding,
                          20,
                          AppSpacing.pagePadding,
                          20,
                        ),
                        children: [
                          const _SuccessSeal(),
                          const SizedBox(height: 14),
                          Text(
                            'Thank You',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your ${_brandedPlanName(plan)} subscription is now active.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _SubscriptionSummaryCard(
                            plan: plan,
                            orderCode: orderCode,
                            features: enabledFeatures,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              const Expanded(
                                child: _StatusTile(
                                  icon: Icons.event_available_rounded,
                                  label: 'NEXT SCAN',
                                  value: 'Available now',
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _StatusTile(
                                  icon: Icons.verified_user_outlined,
                                  label: 'ACCOUNT STATUS',
                                  value: renewalDate == null
                                      ? 'Verified Pro'
                                      : 'Renews ${DateFormat('MMM d').format(renewalDate!)}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            '"Your journey to radiant, healthy skin begins now. A confirmation has been sent to your inbox."',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.mutedText,
                                  fontStyle: FontStyle.italic,
                                  height: 1.45,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pagePadding,
                        8,
                        AppSpacing.pagePadding,
                        14,
                      ),
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.dashboard,
                          (route) => false,
                        ),
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Go to Dashboard'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(child: _ConfettiOverlay()),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessSeal extends StatelessWidget {
  const _SuccessSeal();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: 94,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  width: 8,
                ),
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.onPrimary,
                size: 25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionSummaryCard extends StatelessWidget {
  const _SubscriptionSummaryCard({
    required this.plan,
    required this.orderCode,
    required this.features,
  });

  final SubscriptionPlan plan;
  final int orderCode;
  final List<SubscriptionPlanFeature> features;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SummaryValue(
                  label: 'PLAN SELECTED',
                  value: _brandedPlanName(plan),
                ),
              ),
              const SizedBox(width: 12),
              _SummaryValue(
                label: 'TRANSACTION ID',
                value: _shortOrderCode(orderCode),
                alignEnd: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'BENEFITS NOW ACTIVE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          if (features.isEmpty)
            const _BenefitRow(label: 'Premium membership benefits')
          else
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BenefitRow(label: _featureLabel(feature)),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.primary,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.heading,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primary,
            size: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.heading,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 17),
          const SizedBox(height: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.heading,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay();

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _pieces;

  @override
  void initState() {
    super.initState();
    final random = math.Random(27);
    const colors = [
      AppColors.primary,
      AppColors.primaryContainer,
      AppColors.accent,
      AppColors.tertiary,
      AppColors.secondaryAction,
    ];
    _pieces = List.generate(
      52,
      (index) => _ConfettiPiece(
        x: random.nextDouble(),
        startY: -0.18 - random.nextDouble() * 0.45,
        drift: (random.nextDouble() - 0.5) * 0.28,
        speed: 0.75 + random.nextDouble() * 0.7,
        size: 3 + random.nextDouble() * 5,
        rotation: random.nextDouble() * math.pi,
        turns: 1.5 + random.nextDouble() * 3,
        color: colors[random.nextInt(colors.length)],
        isCircle: random.nextBool(),
      ),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _ConfettiPainter(progress: _controller.value, pieces: _pieces),
        size: Size.infinite,
      ),
    );
  }
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.x,
    required this.startY,
    required this.drift,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.turns,
    required this.color,
    required this.isCircle,
  });

  final double x;
  final double startY;
  final double drift;
  final double speed;
  final double size;
  final double rotation;
  final double turns;
  final Color color;
  final bool isCircle;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress, required this.pieces});

  final double progress;
  final List<_ConfettiPiece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final fall = progress * piece.speed;
      final y = (piece.startY + fall) * size.height;
      if (y < -20 || y > size.height + 20) {
        continue;
      }

      final wave = math.sin(progress * math.pi * 4 + piece.rotation) * 0.035;
      final x = (piece.x + piece.drift * progress + wave) * size.width;
      final opacity = progress > 0.82
          ? ((1 - progress) / 0.18).clamp(0.0, 1.0)
          : 1.0;
      final paint = Paint()..color = piece.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(piece.rotation + progress * math.pi * 2 * piece.turns);
      if (piece.isCircle) {
        canvas.drawCircle(Offset.zero, piece.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size,
            height: piece.size * 1.8,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

String _brandedPlanName(SubscriptionPlan plan) {
  final name = plan.name.trim().isEmpty ? plan.code.trim() : plan.name.trim();
  return name.toLowerCase().startsWith('skinsync') ? name : 'SkinSync $name';
}

String _shortOrderCode(int orderCode) {
  final value = orderCode.toString();
  final suffix = value.length <= 7 ? value : value.substring(value.length - 7);
  return '#SS-$suffix';
}

String _featureLabel(SubscriptionPlanFeature feature) {
  final name = feature.displayName.trim().isEmpty
      ? feature.featureKey.replaceAll('_', ' ')
      : feature.displayName.trim();
  if (feature.isUnlimited) {
    return 'Unlimited $name';
  }
  final limit = feature.monthlyLimit;
  if (limit != null && limit > 0) {
    return '$limit $name each month';
  }
  return name;
}
