import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/section_header.dart';
import 'skin_progress_controller.dart';
import 'skin_progress_models.dart';
import 'skin_progress_repository.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final ImagePicker _picker = ImagePicker();
  SkinProgressController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) {
      return;
    }

    final apiClient = context.read<AppState>().apiClient;
    _controller = SkinProgressController(SkinProgressRepository(apiClient));
    _controller!.loadInitial();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: Center(
            child: Text(
              'Progress loading...',
              style: TextStyle(fontSize: 18, color: AppColors.primaryDark),
            ),
          ),
        ),
      );
    }

    return ChangeNotifierProvider<SkinProgressController>.value(
      value: controller,
      child: _ProgressContent(onPickImage: _pickAndUploadImage),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Add skin progress photo',
                  style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Upload a clear photo and SkinSync will analyze it right away for your progress timeline.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Take photo',
                  icon: const Icon(Icons.camera_alt_outlined),
                  onPressed: () => Navigator.pop(sheetContext, ImageSource.camera),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Choose from gallery',
                  icon: const Icon(Icons.photo_library_outlined),
                  variant: AppButtonVariant.secondary,
                  onPressed: () =>
                      Navigator.pop(sheetContext, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) {
      return;
    }

    try {
      await controller.uploadAndAnalyze(File(picked.path));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skin progress photo analyzed successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanErrorMessage(error))),
      );
    }
  }
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent({required this.onPickImage});

  final Future<void> Function() onPickImage;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final controller = context.watch<SkinProgressController>();
    final dashboard = controller.dashboard;

    return AppScaffold(
      title: 'Progress',
      subtitle:
          'Track your skin journey with premium visuals, condition trends, and AI-generated progress reports.',
      onRefresh: controller.refresh,
      headerTrailing: AppButton(
        label: controller.isUploading ? 'Analyzing...' : 'Add photo',
        icon: const Icon(Icons.add_a_photo_outlined),
        expand: false,
        isLoading: controller.isUploading,
        onPressed: onPickImage,
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.bottomNavHeight + 64,
        ),
        children: [
          _PeriodSelector(
            periodType: controller.periodType,
            anchorDate: controller.anchorDate,
            onPeriodChanged: controller.setPeriodType,
            onAnchorTap: () => _pickPeriodDate(context, controller),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          if (controller.errorMessage != null) ...[
            _ErrorCard(
              message: controller.errorMessage!,
              onRetry: controller.refresh,
            ),
            const SizedBox(height: AppSpacing.sectionGap),
          ],
          if (controller.isLoading && dashboard == null)
            const _LoadingCard()
          else if (dashboard == null || !dashboard.hasPhotos)
            EmptyStateCard(
              icon: Icons.photo_camera_back_outlined,
              title: 'No progress photos yet',
              description:
                  'Upload a clear skin photo and SkinSync will start building your progress dashboard from real tracked data.',
              ctaLabel: 'Start with a photo',
              onCta: onPickImage,
            )
          else ...[
            _SummarySection(dashboard: dashboard),
            const SizedBox(height: AppSpacing.sectionGap),
            _ConditionSection(scores: dashboard.conditionScores),
            const SizedBox(height: AppSpacing.sectionGap),
            _JourneySection(
              dashboard: dashboard,
              isComparing: controller.isComparing,
              onCompare: () => _openCompareSheet(context, controller),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            _ReportSection(
              dashboard: dashboard,
              reports: controller.reports,
              isGenerating: controller.isGeneratingReport,
              onGenerate: () => _generateReport(context, controller),
              onOpenReport: (report) =>
                  _openReportSheet(context, controller, report.reportId),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            _GallerySection(
              photos: dashboard.photoGallery,
              onOpenPhoto: (photo) => _openPhotoSheet(context, photo),
              onDeletePhoto: (photo) =>
                  _confirmDeletePhoto(context, controller, photo),
            ),
          ],
          const SizedBox(height: AppSpacing.sectionGap),
          _ContextActions(
            todayLogNote: appState.todayLog?.notes,
            onOpenCheckup: () =>
                Navigator.pushNamed(context, AppRoutes.todayCheckup),
            onOpenScan: () => Navigator.pushNamed(context, AppRoutes.upload),
            onOpenChat: () => Navigator.pushNamed(
              context,
              AppRoutes.aiChatConversation,
              arguments: const AiChatLaunchArgs(entryPoint: 'progress_dashboard'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPeriodDate(
    BuildContext context,
    SkinProgressController controller,
  ) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: controller.anchorDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selected == null) {
      return;
    }

    await controller.setAnchorDate(selected);
  }

  Future<void> _openCompareSheet(
    BuildContext context,
    SkinProgressController controller,
  ) async {
    try {
      final comparison = await controller.compareCurrentJourney();
      if (!context.mounted) {
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _CompareSheet(comparison: comparison),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanErrorMessage(error))),
      );
    }
  }

  Future<void> _generateReport(
    BuildContext context,
    SkinProgressController controller,
  ) async {
    try {
      final report = await controller.generateCurrentReport();
      if (!context.mounted) {
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _ReportDetailSheet(report: report),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanErrorMessage(error))),
      );
    }
  }

  Future<void> _openReportSheet(
    BuildContext context,
    SkinProgressController controller,
    String reportId,
  ) async {
    try {
      final report = await controller.openReport(reportId);
      if (!context.mounted) {
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _ReportDetailSheet(report: report),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanErrorMessage(error))),
      );
    }
  }

  Future<void> _confirmDeletePhoto(
    BuildContext context,
    SkinProgressController controller,
    SkinProgressPhoto photo,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete progress photo?'),
        content: const Text(
          'This removes the saved photo from your progress tracking dashboard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await controller.deletePhoto(photo.photoId);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanErrorMessage(error))),
      );
    }
  }

  Future<void> _openPhotoSheet(BuildContext context, SkinProgressPhoto photo) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PhotoDetailSheet(photo: photo),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.periodType,
    required this.anchorDate,
    required this.onPeriodChanged,
    required this.onAnchorTap,
  });

  final String periodType;
  final DateTime anchorDate;
  final ValueChanged<String> onPeriodChanged;
  final VoidCallback onAnchorTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Tracking period',
            subtitle: 'Review your skin journey by week, month, or year.',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _PeriodChip(
                label: 'Weekly',
                selected: periodType == 'weekly',
                onTap: () => onPeriodChanged('weekly'),
              ),
              _PeriodChip(
                label: 'Monthly',
                selected: periodType == 'monthly',
                onTap: () => onPeriodChanged('monthly'),
              ),
              _PeriodChip(
                label: 'Yearly',
                selected: periodType == 'yearly',
                onTap: () => onPeriodChanged('yearly'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: _periodLabel(periodType, anchorDate),
            variant: AppButtonVariant.secondary,
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: onAnchorTap,
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: selected ? AppColors.primaryDark : AppColors.mutedText,
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.dashboard});

  final SkinProgressDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.surfaceStrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress overview',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _progressCopy(dashboard.progressStatus),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: dashboard.progressStatus),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MetricCell(
                  label: 'Skin type',
                  value: _friendlyValue(dashboard.summary.skinType),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricCell(
                  label: 'Hydration',
                  value: _friendlyValue(dashboard.summary.hydration),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricCell(
                  label: 'Oiliness',
                  value: _friendlyValue(dashboard.summary.oiliness),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionSection extends StatelessWidget {
  const _ConditionSection({required this.scores});

  final List<SkinProgressConditionScore> scores;

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      return EmptyStateCard(
        icon: Icons.insights_outlined,
        title: 'No condition scores yet',
        description:
            'Analyze a progress photo to see hydration, texture, redness, and other condition scores here.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Condition scores',
          subtitle: 'A quick snapshot of the tracked skin conditions in this period.',
        ),
        const SizedBox(height: AppSpacing.md),
        ...scores.map(
          (score) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          score.label,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          score.change == null
                              ? 'Not enough data to compare yet.'
                              : _changeLabel(score.change!),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${score.score}/100',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      SizedBox(
                        width: 96,
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: (score.score.clamp(0, 100)) / 100,
                          backgroundColor: AppColors.surfaceStrong,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _JourneySection extends StatelessWidget {
  const _JourneySection({
    required this.dashboard,
    required this.isComparing,
    required this.onCompare,
  });

  final SkinProgressDashboard dashboard;
  final bool isComparing;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    final before = dashboard.visualJourney.beforePhoto;
    final after = dashboard.visualJourney.afterPhoto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Visual journey',
          subtitle: 'Place earlier and later photos side by side to review visible changes.',
          trailing: AppButton(
            label: 'Compare',
            variant: AppButtonVariant.ai,
            expand: false,
            isLoading: isComparing,
            onPressed: dashboard.canCompare ? onCompare : null,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: _JourneyImageCard(
                  label: 'Before',
                  photo: before,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _JourneyImageCard(
                  label: 'After',
                  photo: after,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JourneyImageCard extends StatelessWidget {
  const _JourneyImageCard({required this.label, required this.photo});

  final String label;
  final SkinProgressPhoto? photo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 0.82,
            child: photo == null
                ? Container(
                    color: AppColors.surfaceMuted,
                    alignment: Alignment.center,
                    child: Text(
                      'Not provided yet',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : _ProgressImage(imageUrl: photo!.imageUrl),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          photo == null
              ? 'Add another photo to compare progress.'
              : DateFormat('dd MMM yyyy').format(photo!.photoDate),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.dashboard,
    required this.reports,
    required this.isGenerating,
    required this.onGenerate,
    required this.onOpenReport,
  });

  final SkinProgressDashboard dashboard;
  final List<SkinProgressReportSummary> reports;
  final bool isGenerating;
  final VoidCallback onGenerate;
  final ValueChanged<SkinProgressReportSummary> onOpenReport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'AI reports',
          subtitle: 'Generate a premium summary for this period or revisit past reports.',
          trailing: AppButton(
            label: 'Generate',
            variant: AppButtonVariant.ai,
            expand: false,
            isLoading: isGenerating,
            onPressed: onGenerate,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Latest report summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                dashboard.aiReportSummary?.trim().isNotEmpty == true
                    ? dashboard.aiReportSummary!
                    : 'Not provided yet. Generate a report to get a period summary, skin condition changes, and next-step suggestions.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        if (reports.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          ...reports.take(4).map(
            (report) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                onTap: () => onOpenReport(report),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_capitalize(report.periodType)} report',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            report.summary.trim().isEmpty
                                ? 'Not provided yet'
                                : report.summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.mutedText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _GallerySection extends StatelessWidget {
  const _GallerySection({
    required this.photos,
    required this.onOpenPhoto,
    required this.onDeletePhoto,
  });

  final List<SkinProgressPhoto> photos;
  final ValueChanged<SkinProgressPhoto> onOpenPhoto;
  final ValueChanged<SkinProgressPhoto> onDeletePhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Photo gallery',
          subtitle: 'Every saved progress image stays here for your timeline.',
        ),
        const SizedBox(height: AppSpacing.md),
        ...photos.map(
          (photo) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: 86,
                      height: 100,
                      child: _ProgressImage(imageUrl: photo.imageUrl),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy').format(photo.photoDate),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _friendlyValue(photo.note),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'Open',
                                variant: AppButtonVariant.secondary,
                                onPressed: () => onOpenPhoto(photo),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: AppButton(
                                label: 'Delete',
                                variant: AppButtonVariant.danger,
                                onPressed: () => onDeletePhoto(photo),
                              ),
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
      ],
    );
  }
}

class _ContextActions extends StatelessWidget {
  const _ContextActions({
    required this.todayLogNote,
    required this.onOpenCheckup,
    required this.onOpenScan,
    required this.onOpenChat,
  });

  final String? todayLogNote;
  final VoidCallback onOpenCheckup;
  final VoidCallback onOpenScan;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keep the journey moving',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            todayLogNote?.trim().isNotEmpty == true
                ? todayLogNote!
                : 'Update your check-in, run a fresh scan, or ask SkinSync AI for help interpreting your progress.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Check-in',
                  variant: AppButtonVariant.secondary,
                  onPressed: onOpenCheckup,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Scan',
                  variant: AppButtonVariant.secondary,
                  onPressed: onOpenScan,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Ask AI',
                  variant: AppButtonVariant.ai,
                  onPressed: onOpenChat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Something needs attention',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Try again',
            onPressed: () => onRetry(),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Building your progress dashboard.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CompareSheet extends StatelessWidget {
  const _CompareSheet({required this.comparison});

  final SkinProgressComparison comparison;

  @override
  Widget build(BuildContext context) {
    return _DetailSheet(
      title: 'Skin progress comparison',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comparison.comparisonSummary.isEmpty
                ? 'Not provided yet'
                : comparison.comparisonSummary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          ..._comparisonRows(comparison.scoreChanges).map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(child: Text(row.$1)),
                  Text(_changeLabel(row.$2)),
                ],
              ),
            ),
          ),
          if (comparison.recommendations.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Recommendations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...comparison.recommendations.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text('• $item'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportDetailSheet extends StatelessWidget {
  const _ReportDetailSheet({required this.report});

  final SkinProgressReportDetail report;

  @override
  Widget build(BuildContext context) {
    return _DetailSheet(
      title: '${_capitalize(report.periodType)} report',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.summary.isEmpty ? 'Not provided yet' : report.summary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          ..._comparisonRows(report.scoreChanges).map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(child: Text(row.$1)),
                  Text(_changeLabel(row.$2)),
                ],
              ),
            ),
          ),
          if (report.mainFindings.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Main findings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...report.mainFindings.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text('• $item'),
              ),
            ),
          ],
          if ((report.routineFeedback ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Routine feedback',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(report.routineFeedback!),
          ],
          if (report.nextSuggestions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Next suggestions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...report.nextSuggestions.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text('• $item'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoDetailSheet extends StatelessWidget {
  const _PhotoDetailSheet({required this.photo});

  final SkinProgressPhoto photo;

  @override
  Widget build(BuildContext context) {
    return _DetailSheet(
      title: DateFormat('dd MMM yyyy').format(photo.photoDate),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 0.78,
              child: _ProgressImage(imageUrl: photo.imageUrl),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Time of day: ${_friendlyValue(photo.timeOfDay)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Lighting: ${_friendlyValue(photo.lightingCondition)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Face angle: ${_friendlyValue(photo.faceAngle)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _friendlyValue(photo.note),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status.toLowerCase()) {
      'improved' || 'improving' => (AppColors.success, 'Improving'),
      'worse' || 'worsening' => (AppColors.warning, 'Needs attention'),
      'stable' => (AppColors.primaryDark, 'Stable'),
      'mixed' => (AppColors.primary, 'Mixed'),
      _ => (AppColors.mutedText, 'Insufficient data'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
        ),
      ),
    );
  }
}

class _ProgressImage extends StatelessWidget {
  const _ProgressImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final normalized = imageUrl.startsWith('http')
        ? imageUrl
        : '${AppConfig.apiBaseUrl}$imageUrl';

    return Image.network(
      normalized,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppColors.surfaceMuted,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported_outlined),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          color: AppColors.surfaceMuted,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
          ),
        );
      },
    );
  }
}

String _periodLabel(String periodType, DateTime date) {
  if (periodType == 'weekly') {
    final start = date.subtract(Duration(days: date.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM').format(end)}';
  }
  if (periodType == 'yearly') {
    return DateFormat('yyyy').format(date);
  }
  return DateFormat('MMMM yyyy').format(date);
}

String _progressCopy(String status) {
  switch (status.toLowerCase()) {
    case 'improved':
    case 'improving':
      return 'Your latest progress photos suggest visible improvement in this period.';
    case 'worse':
    case 'worsening':
      return 'Some tracked skin conditions look more active in the latest photo.';
    case 'stable':
      return 'Your skin condition looks fairly stable across the selected period.';
    case 'mixed':
      return 'Some areas improved while others still need extra care.';
    default:
      return 'Add another photo to unlock clearer progress comparisons.';
  }
}

String _cleanErrorMessage(Object error) {
  final value = error.toString().replaceFirst('Exception: ', '').trim();
  if (value.isEmpty) {
    return 'Something went wrong. Please try again.';
  }
  return value;
}

String _capitalize(String value) {
  final normalized = value.trim().replaceAll('_', ' ');
  if (normalized.isEmpty) {
    return normalized;
  }
  return normalized[0].toUpperCase() + normalized.substring(1);
}

String _friendlyValue(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty || trimmed == 'Unknown' || trimmed == 'unknown') {
    return 'Not provided yet';
  }
  return _capitalize(trimmed);
}

String _changeLabel(int change) {
  if (change == 0) {
    return 'Stable';
  }
  if (change < 0) {
    return '${change.abs()} better';
  }
  return '+$change worse';
}

List<(String, int)> _comparisonRows(SkinProgressScoreChanges changes) {
  return [
    ('Acne', changes.acneScoreChange),
    ('Redness', changes.rednessScoreChange),
    ('Dark spots', changes.darkSpotScoreChange),
    ('Oiliness', changes.oilinessScoreChange),
    ('Dryness', changes.drynessScoreChange),
    ('Texture', changes.textureScoreChange),
    ('Sensitivity', changes.sensitivityScoreChange),
    ('Overall', changes.overallScoreChange),
  ];
}
