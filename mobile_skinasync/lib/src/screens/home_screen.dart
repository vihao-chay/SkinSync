import 'package:flutter/material.dart';

import '../auth/auth_models.dart';
import '../theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user, required this.onLogout});

  final AuthUser user;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: SkinSyncGradients.warmBackground,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _HomeHeader(user: user)),
              SliverToBoxAdapter(child: _HeroPanel(user: user)),
              const SliverToBoxAdapter(child: _StatsStrip()),
              const SliverToBoxAdapter(child: _FeatureSection()),
              SliverToBoxAdapter(child: _NextSteps(onLogout: onLogout)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SkinSyncGradients.brand,
            ),
            child: Center(
              child: Text(
                user.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xin chào,',
                  style: TextStyle(
                    color: SkinSyncColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: SkinSyncColors.border.withValues(alpha: .55),
              ),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: SkinSyncColors.cocoa,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [
              SkinSyncColors.espresso,
              Color(0xFF3D2A14),
              SkinSyncColors.cocoa,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: SkinSyncColors.cocoa.withValues(alpha: .22),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: SkinSyncColors.sand,
                        size: 15,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'AI Skin Journey',
                        style: TextStyle(
                          color: Color(0xFFE8D5B7),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.health_and_safety_outlined,
                  color: Colors.white70,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Làn da hoàn hảo\nbắt đầu từ AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 31,
                height: 1.08,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Phân tích chuyên sâu, cá nhân hóa lộ trình và theo dõi tiến trình mỗi ngày trong một trải nghiệm mobile gọn gàng.',
              style: TextStyle(
                color: Color(0xFFD4B896),
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            const _SkinScorePreview(),
          ],
        ),
      ),
    );
  }
}

class _SkinScorePreview extends StatelessWidget {
  const _SkinScorePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: SkinSyncColors.cream,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.face_retouching_natural_outlined,
              color: SkinSyncColors.cocoa,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Điểm da mẫu',
                  style: TextStyle(
                    color: SkinSyncColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '87/100',
                  style: TextStyle(
                    color: SkinSyncColors.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    value: .87,
                    minHeight: 7,
                    color: SkinSyncColors.sand,
                    backgroundColor: SkinSyncColors.cream,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: SkinSyncColors.sand,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData('50K+', 'Người dùng', Icons.groups_2_outlined),
      _StatData('98%', 'Chính xác', Icons.psychology_alt_outlined),
      _StatData('4.9', 'Đánh giá', Icons.star_rate_rounded),
    ];

    return SizedBox(
      height: 104,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => _StatCard(data: stats[index]),
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemCount: stats.length,
      ),
    );
  }
}

class _StatData {
  const _StatData(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SkinSyncColors.border.withValues(alpha: .55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, color: SkinSyncColors.sand, size: 21),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: const TextStyle(
              color: SkinSyncColors.espresso,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SkinSyncColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection();

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureData(
        icon: Icons.center_focus_strong_rounded,
        title: 'Phân tích sâu',
        description:
            'AI đọc các chỉ số da chính và gợi ý hướng chăm sóc phù hợp.',
        color: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
      ),
      _FeatureData(
        icon: Icons.track_changes_rounded,
        title: 'Cá nhân hóa',
        description: 'Lộ trình theo loại da, mục tiêu và thói quen hằng ngày.',
        color: const Color(0xFFF0FDF4),
        iconColor: const Color(0xFF16A34A),
      ),
      _FeatureData(
        icon: Icons.shield_outlined,
        title: 'An toàn',
        description: 'Ưu tiên thành phần lành tính và cảnh báo khi có rủi ro.',
        color: const Color(0xFFFFF7ED),
        iconColor: const Color(0xFFEA580C),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tại sao chọn SkinSync',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'Phiên bản mobile giữ tinh thần FE: sạch, ấm, rõ luồng và tập trung vào chăm sóc da bằng AI.',
            style: TextStyle(
              color: SkinSyncColors.muted,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FeatureTile(feature: feature),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureData {
  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color iconColor;
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature});

  final _FeatureData feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SkinSyncColors.border.withValues(alpha: .45)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: feature.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(feature.icon, color: feature.iconColor),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  feature.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextSteps extends StatefulWidget {
  const _NextSteps({required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  State<_NextSteps> createState() => _NextStepsState();
}

class _NextStepsState extends State<_NextSteps> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: SkinSyncGradients.brand,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: SkinSyncColors.sand.withValues(alpha: .26),
                    blurRadius: 18,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Màn khảo sát/analysis sẽ được nối tiếp sau.',
                    ),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Bắt đầu phân tích da'),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _isLoggingOut ? null : _logout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    await widget.onLogout();
    if (!mounted) return;
    setState(() => _isLoggingOut = false);
  }
}
