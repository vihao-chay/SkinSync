import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
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
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.pageBottomPaddingWithActions,
        ),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isProgressFlow
                      ? 'Today\'s scan preview'
                      : 'Upload your skin photo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Keep your face centered, avoid heavy filters, and let SkinSync read your skin clearly.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_a_photo_outlined,
                              size: 52,
                              color: AppColors.primaryDark,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Take a photo or choose from gallery',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
                const _TipRow(
                  icon: Icons.light_mode_outlined,
                  text: 'Good lighting',
                ),
                const SizedBox(height: AppSpacing.sm),
                const _TipRow(
                  icon: Icons.face_rounded,
                  text: 'Face forward',
                ),
                const SizedBox(height: AppSpacing.sm),
                const _TipRow(
                  icon: Icons.filter_alt_off_outlined,
                  text: 'No heavy filter',
                ),
                const SizedBox(height: AppSpacing.lg),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 360) {
                      return Column(
                        children: [
                          AppButton(
                            label: 'Take photo',
                            variant: AppButtonVariant.secondary,
                            icon: const Icon(Icons.camera_alt_outlined),
                            onPressed: appState.isBusy
                                ? null
                                : () => _pickImage(ImageSource.camera),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppButton(
                            label: 'Choose gallery',
                            variant: AppButtonVariant.secondary,
                            icon: const Icon(Icons.photo_library_outlined),
                            onPressed: appState.isBusy
                                ? null
                                : () => _pickImage(ImageSource.gallery),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Take photo',
                            variant: AppButtonVariant.secondary,
                            icon: const Icon(Icons.camera_alt_outlined),
                            onPressed: appState.isBusy
                                ? null
                                : () => _pickImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppButton(
                            label: 'Choose gallery',
                            variant: AppButtonVariant.secondary,
                            icon: const Icon(Icons.photo_library_outlined),
                            onPressed: appState.isBusy
                                ? null
                                : () => _pickImage(ImageSource.gallery),
                          ),
                        ),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Analyze skin',
                  isLoading: appState.isBusy,
                  onPressed: _selectedImage == null || appState.isBusy
                      ? null
                      : _analyzeSkin,
                ),
              ],
            ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 20),
          const SizedBox(width: 10),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
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
