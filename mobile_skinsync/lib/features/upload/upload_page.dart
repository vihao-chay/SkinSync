import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass_header.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/responsive_container.dart';

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

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const GlassHeader(currentRoute: AppRoutes.upload),
      body: ResponsiveContainer(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload your skin photo',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Use a clear portrait in natural light for the best AI read.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 300,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: _selectedImage == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 52,
                                      color: AppColors.primaryDark,
                                    ),
                                    SizedBox(height: 12),
                                    Text('Take a photo or choose from gallery'),
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
                        const SizedBox(height: 16),
                        const _TipRow(
                          icon: Icons.light_mode_outlined,
                          text: 'Good lighting',
                        ),
                        const SizedBox(height: 10),
                        const _TipRow(
                          icon: Icons.face_rounded,
                          text: 'Face forward',
                        ),
                        const SizedBox(height: 10),
                        const _TipRow(
                          icon: Icons.filter_alt_off_outlined,
                          text: 'No heavy filter',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: appState.isBusy
                                    ? null
                                    : () => _pickImage(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: const Text('Take Photo'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: appState.isBusy
                                    ? null
                                    : () => _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Choose Gallery'),
                              ),
                            ),
                          ],
                        ),
                        if (appState.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            appState.errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.error),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GradientPillButton(
                  label: 'Analyze Skin',
                  isLoading: appState.isBusy,
                  expanded: true,
                  onPressed: _selectedImage == null || appState.isBusy
                      ? null
                      : _analyzeSkin,
                ),
              ],
            ),
          ),
        ),
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
    await appState.analyzeSkin(image);

    if (!mounted) {
      return;
    }

    Navigator.pushReplacementNamed(context, AppRoutes.analysis);
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
