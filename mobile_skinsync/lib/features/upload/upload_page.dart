import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/responsive/responsive.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_scaffold.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final flowArgs =
        ModalRoute.of(context)?.settings.arguments as SkinAnalysisFlowArgs?;
    final isProgressFlow = flowArgs?.source == 'progress';
    final noticeMessage = _membershipNotice(appState.errorMessage);

    return AppScaffold(
      title: isProgressFlow ? 'Add a progress photo' : 'Upload Photo',
      subtitle: isProgressFlow
          ? 'Analyze a fresh photo and save it straight into your skin progress timeline.'
          : 'Use a clear portrait in natural light for the best AI read.',
      compactHeader: true,
      showBackButton: true,
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          Responsive.responsiveHorizontalPadding(context),
          0,
          Responsive.responsiveHorizontalPadding(context),
          Responsive.contentBottomSpacing(context, extra: 20),
        ),
        children: [
          Text(
            isProgressFlow ? 'Today\'s scan preview' : 'High-quality photos',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.heading,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _UploadPickerCard(
            selectedImage: _selectedImage,
            onTap: appState.isBusy
                ? null
                : () => _pickImage(ImageSource.gallery),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tips for best results'.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.heading,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const _TipRow(
            icon: Icons.light_mode_outlined,
            text: 'Good lighting, preferably natural daylight',
          ),
          const SizedBox(height: AppSpacing.xs),
          const _TipRow(
            icon: Icons.face_rounded,
            text: 'Face forward directly at the camera',
          ),
          const SizedBox(height: AppSpacing.xs),
          const _TipRow(
            icon: Icons.filter_alt_off_outlined,
            text: 'No heavy makeup or filters applied',
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 420;
              final takePhoto = _CompactOutlineAction(
                label: 'Take photo',
                icon: Icons.camera_alt_outlined,
                onPressed: appState.isBusy
                    ? null
                    : () => _pickImage(ImageSource.camera),
              );
              final chooseGallery = _CompactOutlineAction(
                label: 'Choose gallery',
                icon: Icons.photo_library_outlined,
                onPressed: appState.isBusy
                    ? null
                    : () => _pickImage(ImageSource.gallery),
              );

              if (stack) {
                return Column(
                  children: [
                    SizedBox(width: double.infinity, child: takePhoto),
                    const SizedBox(height: AppSpacing.xs),
                    SizedBox(width: double.infinity, child: chooseGallery),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: takePhoto),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: chooseGallery),
                ],
              );
            },
          ),
          if (noticeMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            _NoticeBanner(message: noticeMessage),
          ] else if (appState.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              appState.errorMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          _AnalyzeButton(
            isLoading: appState.isBusy,
            onPressed: _selectedImage == null || appState.isBusy
                ? null
                : _analyzeSkin,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    context.read<AppState>().clearError();
    setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _analyzeSkin() async {
    final image = _selectedImage;
    if (image == null) {
      return;
    }

    final appState = context.read<AppState>();
    final flowArgs =
        ModalRoute.of(context)?.settings.arguments as SkinAnalysisFlowArgs?;
    try {
      await appState.analyzeSkinPhoto(
        image,
        source: flowArgs?.source ?? 'unknown',
      );
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, AppRoutes.analysis);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }
  }
}

class _UploadPickerCard extends StatelessWidget {
  const _UploadPickerCard({required this.selectedImage, required this.onTap});

  final File? selectedImage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted.withValues(alpha: 0.46),
      borderRadius: BorderRadius.circular(AppRadius.small),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: AppColors.border,
            radius: AppRadius.small,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 166,
            child: selectedImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.foreground.withValues(
                                alpha: 0.04,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 19,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Tap to upload or take a photo',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.heading,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    child: Image.file(
                      selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 5;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _CompactOutlineAction extends StatelessWidget {
  const _CompactOutlineAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 13),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        textStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.72)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}

class _AnalyzeButton extends StatelessWidget {
  const _AnalyzeButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(38),
        backgroundColor: isEnabled
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.34),
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.34),
        disabledForegroundColor: AppColors.onPrimary.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        textStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: isLoading
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Analyze skin'),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.workspace_premium_outlined,
              size: 18,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primaryDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.heading,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? _membershipNotice(String? message) {
  final raw = message?.trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  final lower = raw.toLowerCase();
  if (lower.contains('quota') || lower.contains('current plan')) {
    return raw;
  }
  return null;
}
