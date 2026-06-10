import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_header.dart';

class AiReportsPage extends StatefulWidget {
  const AiReportsPage({super.key});

  @override
  State<AiReportsPage> createState() => _AiReportsPageState();
}

class _AiReportsPageState extends State<AiReportsPage> {
  late Future<List<AiReportSummary>> _future;
  AiReportGenerateResponse? _selected;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AiReportSummary>> _load() {
    return context.read<AppState>().fetchAiReports();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _generate(String type) async {
    setState(() => _generating = true);
    try {
      final report = await context.read<AppState>().generateAiReport(type);
      if (!mounted) {
        return;
      }
      setState(() {
        _selected = report;
        _future = _load();
      });
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  Future<void> _open(String reportId) async {
    final report = await context.read<AppState>().fetchAiReport(reportId);
    if (!mounted) {
      return;
    }
    setState(() => _selected = report);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const GlassHeader(currentRoute: '/ai/reports', title: 'AI Reports'),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primaryDark,
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in const ['weekly', 'monthly', 'after_analysis'])
                    FilledButton(
                      onPressed: _generating ? null : () => _generate(type),
                      child: Text(_generating ? 'Working...' : 'Generate $type'),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              FutureBuilder<List<AiReportSummary>>(
                future: _future,
                builder: (context, snapshot) {
                  final reports = snapshot.data ?? const <AiReportSummary>[];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saved reports',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const CircularProgressIndicator()
                      else if (reports.isEmpty)
                        const _ReportCard(
                          title: 'No reports yet',
                          body: 'Generate a report after you have enough analysis and routine data.',
                        )
                      else
                        ...reports.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _open(item.reportId),
                              borderRadius: BorderRadius.circular(18),
                              child: _ReportCard(
                                title: '${item.reportType} • ${item.progressEvaluation}',
                                body: item.summary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (_selected != null) ...[
                const SizedBox(height: 18),
                _ReportCard(
                  title: 'Selected report',
                  body: _selected!.summary,
                  extra: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selected!.mainFindings.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ..._selected!.mainFindings.map((item) => Text('• $item')),
                      ],
                      if ((_selected!.routineFeedback ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text('Routine: ${_selected!.routineFeedback!}'),
                      ],
                      if ((_selected!.productFeedback ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Products: ${_selected!.productFeedback!}'),
                      ],
                      if (_selected!.nextPlan.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ..._selected!.nextPlan.map((item) => Text('Next: $item')),
                      ],
                    ],
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

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.title,
    required this.body,
    this.extra,
  });

  final String title;
  final String body;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(body),
          if (extra != null) extra!,
        ],
      ),
    );
  }
}
