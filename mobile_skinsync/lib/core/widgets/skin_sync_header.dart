import 'package:flutter/material.dart';

import '../l10n/app_locale.dart';
import '../responsive/responsive.dart';
import '../theme/app_colors.dart';

class SkinSyncHeader extends StatelessWidget {
  const SkinSyncHeader({
    super.key,
    required this.name,
    this.avatarUrl,
    this.onAvatarTap,
  });

  static const double _logoSize = 40;
  static const double _avatarSize = 35;
  static const double _rightPadding = 23;

  final String name;
  final String? avatarUrl;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final displayName = _shortName(name);
    final imageUrl = avatarUrl?.trim() ?? '';
    final leftPadding = Responsive.responsiveHorizontalPadding(context);

    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.pageBackground),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final greetingWidth =
              (constraints.maxWidth -
                      leftPadding -
                      _rightPadding -
                      _logoSize -
                      _avatarSize -
                      24)
                  .clamp(72.0, 180.0);
          final resolvedGreetingWidth = greetingWidth.toDouble();

          return Padding(
            padding: EdgeInsets.fromLTRB(leftPadding, 11, _rightPadding, 8),
            child: SizedBox(
              height: 40,
              child: Row(
                children: [
                  const _HeaderLogo(),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: resolvedGreetingWidth,
                        ),
                        child: Text(
                          '${locale.tr('dashboard_hello')}, $displayName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.heading,
                                fontWeight: FontWeight.w600,
                                height: 1,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _HeaderAvatar(
                        imageUrl: imageUrl,
                        name: displayName,
                        onTap: onAvatarTap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _shortName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == 'You') {
      return 'SkinSync';
    }
    final emailIndex = trimmed.indexOf('@');
    final source = emailIndex > 0 ? trimmed.substring(0, emailIndex) : trimmed;
    return source.split(RegExp(r'\s+')).first.trim();
  }
}

class _HeaderLogo extends StatelessWidget {
  const _HeaderLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: SkinSyncHeader._logoSize,
      child: Image.asset(
        'logo_perfect.png',
        fit: BoxFit.contain,
        semanticLabel: 'SkinSync logo',
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({
    required this.imageUrl,
    required this.name,
    required this.onTap,
  });

  final String imageUrl;
  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainer,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: SkinSyncHeader._avatarSize,
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      _HeaderAvatarFallback(initial: _initialFromName(name)),
                )
              : _HeaderAvatarFallback(initial: _initialFromName(name)),
        ),
      ),
    );
  }

  String _initialFromName(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty
        ? 'S'
        : String.fromCharCode(trimmed.runes.first).toUpperCase();
  }
}

class _HeaderAvatarFallback extends StatelessWidget {
  const _HeaderAvatarFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}
