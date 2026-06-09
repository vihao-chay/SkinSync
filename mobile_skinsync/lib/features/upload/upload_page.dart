import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/widgets/glass_header.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/section_badge.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassHeader(currentRoute: AppRoutes.analysis),
      body: SingleChildScrollView(
        child: ResponsiveContainer(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionBadge(label: 'Upload', icon: Icons.camera_alt_outlined),
                const SizedBox(height: 14),
                Text('Upload Your Skin Photo', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Use clear lighting, face forward, and avoid heavy makeup or filters when possible.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                PremiumCard(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 280,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F0E8),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.add_a_photo_outlined, size: 60),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: const [
                          _TipCard(icon: Icons.light_mode_outlined, text: 'Good lighting'),
                          _TipCard(icon: Icons.face_retouching_natural_outlined, text: 'Face forward'),
                          _TipCard(icon: Icons.filter_alt_off_outlined, text: 'No heavy filter'),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Take Photo'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Choose from Gallery'),
                          ),
                          GradientPillButton(
                            label: 'Analyze Skin',
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.analysis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }
}
