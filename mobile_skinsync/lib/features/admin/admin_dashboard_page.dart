import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/admin_shell.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/section_badge.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<_AdminDashboardMetrics> _metricsFuture;

  @override
  void initState() {
    super.initState();
    _metricsFuture = _loadMetrics();
  }

  Future<_AdminDashboardMetrics> _loadMetrics() async {
    final data = await context.read<AppState>().apiClient.get(
      '/api/admin/dashboard',
    );
    return _AdminDashboardMetrics.fromJson(data);
  }

  void _refreshMetrics() {
    setState(() {
      _metricsFuture = _loadMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: AppRoutes.admin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionBadge(
            label: 'Admin',
            icon: Icons.admin_panel_settings_outlined,
          ),
          const SizedBox(height: 14),
          Text(
            'Tổng quan quản trị',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Số liệu thật từ backend, bao gồm lượt mở app đầu tiên được tính như lượt tải.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          FutureBuilder<_AdminDashboardMetrics>(
            future: _metricsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const PremiumCard(
                  child: SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (snapshot.hasError) {
                return PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Không tải được số liệu quản trị',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        snapshot.error.toString(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _refreshMetrics,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }

              final metrics = snapshot.data ?? _AdminDashboardMetrics.empty();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: Responsive.gridColumns(
                      context,
                      desktop: 4,
                      tablet: 2,
                      mobile: 1,
                    ),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: Responsive.isMobile(context) ? 2.2 : 1.25,
                    children: [
                      _AdminMetricCard(
                        title: 'Tổng lượt tải',
                        value: metrics.totalDownloads,
                        icon: Icons.download_done_rounded,
                      ),
                      _AdminMetricCard(
                        title: 'Tổng người dùng',
                        value: metrics.totalUsers,
                        icon: Icons.people_alt_outlined,
                      ),
                      _AdminMetricCard(
                        title: 'Người dùng hoạt động',
                        value: metrics.activeUsers,
                        icon: Icons.verified_user_outlined,
                      ),
                      _AdminMetricCard(
                        title: 'Lượt phân tích da',
                        value: metrics.totalAnalyses,
                        icon: Icons.auto_awesome_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phân bổ loại da',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (metrics.skinTypeDistribution.isEmpty)
                          Text(
                            'Chưa có dữ liệu hồ sơ da.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          )
                        else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: metrics.skinTypeDistribution.entries
                                .map(
                                  (entry) => Chip(
                                    label: Text('${entry.key}: ${entry.value}'),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminMetricCard extends StatelessWidget {
  const _AdminMetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 10),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Spacer(),
          Align(alignment: Alignment.bottomRight, child: Icon(icon)),
        ],
      ),
    );
  }
}

class _AdminDashboardMetrics {
  const _AdminDashboardMetrics({
    required this.totalUsers,
    required this.totalDownloads,
    required this.activeUsers,
    required this.totalAnalyses,
    required this.skinTypeDistribution,
  });

  factory _AdminDashboardMetrics.empty() {
    return const _AdminDashboardMetrics(
      totalUsers: 0,
      totalDownloads: 0,
      activeUsers: 0,
      totalAnalyses: 0,
      skinTypeDistribution: {},
    );
  }

  factory _AdminDashboardMetrics.fromJson(Map<String, dynamic> json) {
    final distribution =
        json['skinTypeDistribution'] ?? json['SkinTypeDistribution'];
    return _AdminDashboardMetrics(
      totalUsers: _readInt(json, 'totalUsers', 'TotalUsers'),
      totalDownloads: _readInt(json, 'totalDownloads', 'TotalDownloads'),
      activeUsers: _readInt(json, 'activeUsers', 'ActiveUsers'),
      totalAnalyses: _readInt(json, 'totalAnalyses', 'TotalAnalyses'),
      skinTypeDistribution: distribution is Map
          ? distribution.map(
              (key, value) => MapEntry(
                key.toString(),
                value is int ? value : int.tryParse(value.toString()) ?? 0,
              ),
            )
          : const {},
    );
  }

  final int totalUsers;
  final int totalDownloads;
  final int activeUsers;
  final int totalAnalyses;
  final Map<String, int> skinTypeDistribution;

  static int _readInt(Map<String, dynamic> json, String key, String fallback) {
    final value = json[key] ?? json[fallback];
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
