import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/gradient_pill_button.dart';
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
      return const SizedBox.shrink();
    }

    return ChangeNotifierProvider<SkinProgressController>.value(
      value: controller,
      child: _ProgressContent(onPickImage: _pickAndUploadImage),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final contextRef = context;
    final controller = _controller;
    if (controller == null) {
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: contextRef,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Add Skin Progress Photo',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload a clear photo. SkinSync will analyze it right away and refresh your progress dashboard.',
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  tileColor: AppColors.secondary,
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.primaryDark,
                  ),
                  title: const Text('Take photo'),
                  onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  tileColor: AppColors.secondary,
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.primaryDark,
                  ),
                  title: const Text('Choose from gallery'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.gallery),
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
      ScaffoldMessenger.of(contextRef).showSnackBar(
        const SnackBar(content: Text('Skin progress photo analyzed successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(contextRef).showSnackBar(
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
    final reports = controller.reports;

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.primaryDark,
          onRefresh: controller.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              26,
              AppSpacing.pagePadding,
              124,
            ),
            children: [
              _PeriodSelector(
                periodType: controller.periodType,
                anchorDate: controller.anchorDate,
                onPeriodChanged: controller.setPeriodType,
                onAnchorTap: () => _pickPeriodDate(context, controller),
              ),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: 16),
                _ErrorCard(
                  message: controller.errorMessage!,
                  onRetry: controller.refresh,
                ),
              ],
              const SizedBox(height: 18),
              if (controller.isLoading && dashboard == null)
                const _LoadingCard()
              else if (dashboard == null || !dashboard.hasPhotos)
                _EmptyProgressState(
                  onAddPhoto: onPickImage,
                  onScanNow: () =>
                      Navigator.pushNamed(context, AppRoutes.upload),
                )
              else ...[
                _SummarySection(
                  summary: dashboard.summary,
                  progressStatus: dashboard.progressStatus,
                  photoCount: dashboard.photoGallery.length,
                ),
                const SizedBox(height: 16),
                _ConditionSection(scores: dashboard.conditionScores),
                const SizedBox(height: 16),
                _JourneySection(
                  journey: dashboard.visualJourney,
                  progressStatus: dashboard.progressStatus,
                  isComparing: controller.isComparing,
                  onCompare: () => _openCompareSheet(context, controller),
                ),
                const SizedBox(height: 16),
                _ReportSection(
                  latestSummary: dashboard.aiReportSummary,
                  reports: reports,
                  isGenerating: controller.isGeneratingReport,
                  onGenerate: () => _generateReport(context, controller),
                  onOpenReport: (report) =>
                      _openReportSheet(context, controller, report.reportId),
                ),
                const SizedBox(height: 16),
                _GallerySection(
                  photos: dashboard.photoGallery,
                  onAddPhoto: onPickImage,
                  onOpenPhoto: (photo) => _openPhotoSheet(context, photo),
                  onDeletePhoto: (photo) => _confirmDeletePhoto(
                    context,
                    controller,
                    photo,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _ContextActions(
                todayLogNote: appState.todayLog?.notes,
                onOpenCheckup: () =>
                    Navigator.pushNamed(context, AppRoutes.todayCheckup),
                onOpenScan: () =>
                    Navigator.pushNamed(context, AppRoutes.upload),
                onOpenChat: () =>
                    Navigator.pushNamed(context, AppRoutes.aiChat),
              ),
            ],
          ),
        ),
        Positioned(
          right: 24,
          bottom: 22,
      child: FloatingActionButton.extended(
        heroTag: 'progress-add-photo',
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 5,
        onPressed: controller.isUploading ? null : onPickImage,
        icon: controller.isUploading
            ? const SizedBox(
                width: 18,
                height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.add_rounded),
            label: Text(controller.isUploading ? 'Analyzing...' : 'Add'),
          ),
        ),
      ],
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryDark,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
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
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) => _CompareSheet(comparison: comparison),
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
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) => _ReportDetailSheet(report: report),
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
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) => _ReportDetailSheet(report: report),
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
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete progress photo?'),
          content: const Text(
            'This will remove the saved photo from your progress tracking dashboard.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _PhotoDetailSheet(photo: photo),
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _PeriodChip(
                  label: 'Weekly',
                  selected: periodType == 'weekly',
                  onTap: () => onPeriodChanged('weekly'),
                ),
              ),
              Expanded(
                child: _PeriodChip(
                  label: 'Monthly',
                  selected: periodType == 'monthly',
                  onTap: () => onPeriodChanged('monthly'),
                ),
              ),
              Expanded(
                child: _PeriodChip(
                  label: 'Yearly',
                  selected: periodType == 'yearly',
                  onTap: () => onPeriodChanged('yearly'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: onAnchorTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _periodLabel(periodType, anchorDate),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.primaryDark,
                ),
              ],
            ),
          ),
        ),
      ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? AppColors.primaryDark : AppColors.foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.summary,
    required this.progressStatus,
    required this.photoCount,
  });

  final SkinProgressSummary summary;
  final String progressStatus;
  final int photoCount;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        children: [
          _SummaryRow(
            icon: Icons.spa_outlined,
            label: 'Skin Type',
            value: summary.skinType,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            icon: Icons.water_drop_outlined,
            label: 'Hydration',
            value: summary.hydration,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            icon: Icons.bubble_chart_outlined,
            label: 'Oiliness',
            value: summary.oiliness,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusBadge(status: progressStatus),
              const Spacer(),
              Text(
                '$photoCount photo${photoCount == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
            ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Skin Condition',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            if (scores.isNotEmpty)
              Text(
                'Lower is better',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (scores.isEmpty)
          const _SoftCard(
            child: Text('Analyze a progress photo to see condition scores.'),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: scores
                .map((score) => SizedBox(
                      width: 74,
                      child: _ConditionScoreCard(score: score),
                    ))
                .toList(),
          ),
      ],
    );
  }
}

class _ConditionScoreCard extends StatelessWidget {
  const _ConditionScoreCard({required this.score});

  final SkinProgressConditionScore score;

  @override
  Widget build(BuildContext context) {
    final progress = (score.score.clamp(0, 100)) / 100;
    final change = score.change ?? 0;
    final changeColor = change == 0
        ? AppColors.mutedText
        : change < 0
        ? AppColors.success
        : AppColors.warning;
    final changeText = change == 0
        ? 'Stable'
        : change < 0
        ? '${change.abs()} better'
        : '+$change higher';

    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Column(
        children: [
          Text(
            score.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: AppColors.secondary,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryDark,
                  ),
                ),
                Center(
                  child: Text(
                    '${score.score}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            changeText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: changeColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneySection extends StatelessWidget {
  const _JourneySection({
    required this.journey,
    required this.progressStatus,
    required this.isComparing,
    required this.onCompare,
  });

  final SkinProgressVisualJourney journey;
  final String progressStatus;
  final bool isComparing;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visual Journey',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _JourneyPhotoCard(
                  label: 'Before',
                  photo: journey.beforePhoto,
                  compact: true,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _JourneyPhotoCard(
                  label: 'After',
                  photo: journey.afterPhoto,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: isComparing || journey.afterPhoto == null ? null : onCompare,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.foreground,
              ),
              child: Text(
                isComparing
                    ? 'Comparing...'
                    : journey.afterPhoto == null
                    ? 'Add another photo to compare'
                    : 'Compare Photos',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            journey.afterPhoto == null
                ? 'Add another photo to compare progress.'
                : _progressCopy(progressStatus),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyPhotoCard extends StatelessWidget {
  const _JourneyPhotoCard({
    required this.label,
    this.photo,
    this.compact = false,
  });

  final String label;
  final SkinProgressPhoto? photo;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: compact ? 96 : 136,
            width: double.infinity,
            color: AppColors.secondary,
            child: photo == null
                ? const Icon(Icons.add_photo_alternate_outlined)
                : _ProgressImage(imageUrl: photo!.imageUrl),
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 8),
          Text(
            photo == null
                ? 'No photo yet'
                : DateFormat('dd MMM yyyy').format(photo!.photoDate),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.latestSummary,
    required this.reports,
    required this.isGenerating,
    required this.onGenerate,
    required this.onOpenReport,
  });

  final String? latestSummary;
  final List<SkinProgressReportSummary> reports;
  final bool isGenerating;
  final VoidCallback onGenerate;
  final ValueChanged<SkinProgressReportSummary> onOpenReport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'AI Progress Report',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: isGenerating ? null : onGenerate,
              icon: isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_outlined),
              label: Text(isGenerating ? 'Generating...' : 'Generate'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                latestSummary?.trim().isNotEmpty == true
                    ? latestSummary!
                    : 'Generate a report to get a period summary, skin condition changes, and next-step suggestions.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.foreground,
                  height: 1.45,
                ),
              ),
              if (reports.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Saved reports',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ...reports.take(3).map(
                  (report) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => onOpenReport(report),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_capitalize(report.periodType)} report',
                                    style: Theme.of(context).textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    report.summary,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color: AppColors.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.primaryDark.withValues(alpha: 0.8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GallerySection extends StatelessWidget {
  const _GallerySection({
    required this.photos,
    required this.onAddPhoto,
    required this.onOpenPhoto,
    required this.onDeletePhoto,
  });

  final List<SkinProgressPhoto> photos;
  final Future<void> Function() onAddPhoto;
  final ValueChanged<SkinProgressPhoto> onOpenPhoto;
  final ValueChanged<SkinProgressPhoto> onDeletePhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Photo Gallery',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              onPressed: () => onAddPhoto(),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final photo = photos[index];
              return SizedBox(
                width: 86,
                child: _GalleryPhotoCard(
                  photo: photo,
                  onTap: () => onOpenPhoto(photo),
                  onDelete: () => onDeletePhoto(photo),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GalleryPhotoCard extends StatelessWidget {
  const _GalleryPhotoCard({
    required this.photo,
    required this.onTap,
    required this.onDelete,
  });

  final SkinProgressPhoto photo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: _SoftCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 76,
                width: double.infinity,
                child: _ProgressImage(imageUrl: photo.imageUrl),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM dd').format(photo.photoDate),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onDelete,
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.mutedText.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
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
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keep the streak moving',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            todayLogNote?.trim().isNotEmpty == true
                ? todayLogNote!
                : 'Update your check-up, run a fresh scan, or ask SkinSync AI for help interpreting your progress.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionChip(
                icon: Icons.checklist_rounded,
                label: 'Today Check-up',
                onTap: onOpenCheckup,
              ),
              _ActionChip(
                icon: Icons.auto_awesome_rounded,
                label: 'New Skin Scan',
                onTap: onOpenScan,
              ),
              _ActionChip(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat with SkinSync AI',
                onTap: onOpenChat,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryDark),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.mutedText),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.foreground,
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _CompareSheet extends StatelessWidget {
  const _CompareSheet({required this.comparison});

  final SkinProgressComparison comparison;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Compare Photos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _JourneyPhotoCard(
                      label: 'Before',
                      photo: comparison.beforePhoto,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _JourneyPhotoCard(
                      label: 'After',
                      photo: comparison.afterPhoto,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _StatusBadge(status: comparison.progressStatus),
              const SizedBox(height: 12),
              Text(
                comparison.comparisonSummary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              _SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score changes',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._comparisonRows(comparison.scoreChanges).map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ScoreChangeRow(
                          label: item.$1,
                          change: item.$2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (comparison.improvements.isNotEmpty) ...[
                const SizedBox(height: 16),
                _BulletCard(
                  title: 'Improvements',
                  items: comparison.improvements,
                ),
              ],
              if (comparison.worsenedAreas.isNotEmpty) ...[
                const SizedBox(height: 16),
                _BulletCard(
                  title: 'Needs attention',
                  items: comparison.worsenedAreas,
                ),
              ],
              if (comparison.stableAreas.isNotEmpty) ...[
                const SizedBox(height: 16),
                _BulletCard(title: 'Stable areas', items: comparison.stableAreas),
              ],
              if (comparison.recommendations.isNotEmpty) ...[
                const SizedBox(height: 16),
                _BulletCard(
                  title: 'Recommendations',
                  items: comparison.recommendations,
                ),
              ],
              if ((comparison.confidenceNote ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _SoftCard(
                  child: Text(
                    comparison.confidenceNote!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportDetailSheet extends StatelessWidget {
  const _ReportDetailSheet({required this.report});

  final SkinProgressReportDetail report;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '${_capitalize(report.periodType)} Progress Report',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                '${DateFormat('dd MMM yyyy').format(report.periodStart)} - ${DateFormat('dd MMM yyyy').format(report.periodEnd)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: 14),
              _StatusBadge(status: report.progressStatus),
              const SizedBox(height: 14),
              _SoftCard(
                child: Text(
                  report.summary,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Condition changes',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._comparisonRows(report.scoreChanges).map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ScoreChangeRow(
                          label: item.$1,
                          change: item.$2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (report.mainFindings.isNotEmpty) ...[
                const SizedBox(height: 16),
                _BulletCard(title: 'Main findings', items: report.mainFindings),
              ],
              if ((report.routineFeedback ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Routine feedback',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        report.routineFeedback!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (report.nextSuggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                _BulletCard(
                  title: 'Next suggestions',
                  items: report.nextSuggestions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoDetailSheet extends StatelessWidget {
  const _PhotoDetailSheet({required this.photo});

  final SkinProgressPhoto photo;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              DateFormat('dd MMM yyyy').format(photo.photoDate),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 260,
                width: double.infinity,
                child: _ProgressImage(imageUrl: photo.imageUrl),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '${_capitalize(photo.timeOfDay)} • ${_capitalize(photo.faceAngle)} • ${_capitalize(photo.lightingCondition)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
            ),
            if ((photo.note ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                photo.note!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Something went wrong',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            _cleanErrorMessage(message),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProgressState extends StatelessWidget {
  const _EmptyProgressState({
    required this.onAddPhoto,
    required this.onScanNow,
  });

  final Future<void> Function() onAddPhoto;
  final VoidCallback onScanNow;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.camera_enhance_outlined,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Take your first skin progress photo',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a clear photo and SkinSync will analyze it, save the result, and build your progress dashboard from real tracked data.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          GradientPillButton(
            label: 'Add Skin Photo',
            expanded: true,
            onPressed: () => onAddPhoto(),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onScanNow,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Open skin scan flow'),
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
    return const _SoftCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
          ),
        ),
      ),
    );
  }
}

class _BulletCard extends StatelessWidget {
  const _BulletCard({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.circle,
                      size: 7,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreChangeRow extends StatelessWidget {
  const _ScoreChangeRow({required this.label, required this.change});

  final String label;
  final int change;

  @override
  Widget build(BuildContext context) {
    final color = change == 0
        ? AppColors.mutedText
        : change < 0
        ? AppColors.success
        : AppColors.warning;
    final text = change == 0
        ? 'Stable'
        : change < 0
        ? '${change.abs()} better'
        : '+$change worse';

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final config = switch (status.toLowerCase()) {
      'improving' => (AppColors.success, 'Improving'),
      'worsening' => (AppColors.warning, 'Needs attention'),
      'stable' => (AppColors.primaryDark, 'Stable'),
      _ => (AppColors.mutedText, 'Insufficient data'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: config.$1.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        config.$2,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: config.$1,
          fontWeight: FontWeight.w800,
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
          color: AppColors.secondary,
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.mutedText,
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          color: AppColors.secondary,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
          ),
        );
      },
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
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
    case 'improving':
      return 'Your latest progress photos suggest improvement in this period.';
    case 'worsening':
      return 'Some tracked skin conditions look more active in the latest photo.';
    case 'stable':
      return 'Your condition looks fairly stable across the current period.';
    default:
      return 'Add another photo to compare progress.';
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
