import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    this.width = double.infinity,
    this.height = double.infinity,
    this.radius = 24,
    this.iconSize = 30,
    this.fit = BoxFit.cover,
    this.placeholderTitle,
    this.placeholderSubtitle,
  });

  final String? imageUrl;
  final double width;
  final double height;
  final double radius;
  final double iconSize;
  final BoxFit fit;
  final String? placeholderTitle;
  final String? placeholderSubtitle;

  @override
  Widget build(BuildContext context) {
    final raw = imageUrl?.trim() ?? '';
    final resolvedUrl = raw.isEmpty
        ? ''
        : (raw.startsWith('http') ? raw : '${AppConfig.apiBaseUrl}$raw');

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondary.withValues(alpha: 0.9),
              AppColors.surfaceStrong,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: resolvedUrl.isEmpty
            ? _PlaceholderContent(
                iconSize: iconSize,
                title: placeholderTitle,
                subtitle: placeholderSubtitle,
              )
            : Image.network(
                resolvedUrl,
                fit: fit,
                errorBuilder: (_, _, _) => _PlaceholderContent(
                  iconSize: iconSize,
                  title: placeholderTitle,
                  subtitle: placeholderSubtitle,
                ),
              ),
      ),
    );
  }
}

class _PlaceholderContent extends StatelessWidget {
  const _PlaceholderContent({
    required this.iconSize,
    this.title,
    this.subtitle,
  });

  final double iconSize;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final hasCopy =
        (title?.trim().isNotEmpty ?? false) ||
        (subtitle?.trim().isNotEmpty ?? false);
    if (!hasCopy) {
      return Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          color: AppColors.primaryDark,
          size: iconSize,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            color: AppColors.primaryDark,
            size: iconSize,
          ),
          const SizedBox(height: 8),
          if (title?.trim().isNotEmpty ?? false)
            Text(
              title!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          if (subtitle?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.mutedText,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
