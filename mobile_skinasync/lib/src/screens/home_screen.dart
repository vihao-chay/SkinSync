import 'package:flutter/material.dart';

import '../auth/auth_models.dart';
import '../theme.dart';
import '../widgets/brand_logo.dart';

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
              const SliverToBoxAdapter(child: _HeroSection()),
              const SliverToBoxAdapter(child: _StatsSection()),
              const SliverToBoxAdapter(child: _PhilosophySection()),
              const SliverToBoxAdapter(child: _FeatureSection()),
              const SliverToBoxAdapter(child: _HowItWorksSection()),
              const SliverToBoxAdapter(child: _SkinTypesSection()),
              const SliverToBoxAdapter(child: _TestimonialsSection()),
              const SliverToBoxAdapter(child: _TrustBadgesSection()),
              SliverToBoxAdapter(child: _FinalCtaSection(onLogout: onLogout)),
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
          BrandLogo(
            size: 46,
            borderRadius: 16,
            borderColor: SkinSyncColors.border.withValues(alpha: .7),
            boxShadow: [
              BoxShadow(
                color: SkinSyncColors.cocoa.withValues(alpha: .12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SkinSync',
                  style: TextStyle(
                    color: SkinSyncColors.espresso,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Xin chào, ${user.displayName}',
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
          ),
          IconButton.filledTonal(
            onPressed: () => _showSoon(context, 'Thông báo sẽ được nối sau.'),
            icon: const Icon(Icons.notifications_none_rounded),
            style: IconButton.styleFrom(
              foregroundColor: SkinSyncColors.cocoa,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: SkinSyncColors.border.withValues(alpha: .55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                'https://images.unsplash.com/photo-1590110348915-993aca51ea03'
                '?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const DecoratedBox(
                  decoration: BoxDecoration(gradient: SkinSyncGradients.brand),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SkinSyncColors.espresso.withValues(alpha: .88),
                      SkinSyncColors.cocoa.withValues(alpha: .58),
                      SkinSyncColors.sand.withValues(alpha: .20),
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeroBadge(),
                  const SizedBox(height: 74),
                  const Text(
                    'Lan da hoan hao\nbat dau tu AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 33,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Phân tích chuyên sâu, cá nhân hóa lộ trình, và theo dõi tiến trình mỗi ngày trong một nền tảng thông minh duy nhất.',
                    style: TextStyle(
                      color: Color(0xFFF2DFCA),
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _GradientButton(
                          label: 'Phân tích miễn phí',
                          icon: Icons.auto_awesome_rounded,
                          onPressed: () => _showSoon(
                            context,
                            'Màn khảo sát/analysis sẽ được nối tiếp sau.',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _IconActionButton(
                        icon: Icons.play_arrow_rounded,
                        onPressed: () =>
                            _showSoon(context, 'Demo sẽ được nối sau.'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SkinScorePreview(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_fix_high_rounded, color: Color(0xFFD4F4F4), size: 16),
          SizedBox(width: 8),
          Text(
            'Công nghệ AI tiên tiến',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
        color: Colors.white.withValues(alpha: .93),
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

class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData('98%', 'Độ chính xác AI', Icons.psychology_alt_outlined),
      _StatData('50K+', 'Người dùng tin tưởng', Icons.groups_2_outlined),
      _StatData('2400+', 'Sản phẩm kiểm duyệt', Icons.verified_outlined),
      _StatData('4.9', 'Đánh giá trung bình', Icons.star_rate_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: stats.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.28,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemBuilder: (context, index) => _StatCard(data: stats[index]),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SkinSyncColors.border.withValues(alpha: .55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .025),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, color: SkinSyncColors.sand, size: 21),
          const SizedBox(height: 7),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SkinSyncColors.muted,
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhilosophySection extends StatelessWidget {
  const _PhilosophySection();

  @override
  Widget build(BuildContext context) {
    final bullets = [
      _BulletData(
        icon: Icons.eco_outlined,
        title: 'Nature',
        description: 'Ưu tiên thành phần thiên nhiên, dịu nhẹ với hàng rào da.',
        color: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF15803D),
      ),
      _BulletData(
        icon: Icons.biotech_outlined,
        title: 'Science',
        description:
            'Dữ liệu sản phẩm và hoạt chất được đối chiếu có hệ thống.',
        color: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
      ),
      _BulletData(
        icon: Icons.psychology_alt_outlined,
        title: 'AI',
        description: 'Mô hình gợi ý lộ trình theo ảnh, thói quen và mục tiêu.',
        color: const Color(0xFFF5F0E8),
        iconColor: SkinSyncColors.cocoa,
      ),
    ];

    return _SectionShell(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            eyebrow: 'Nature · Science · AI',
            title: 'Triết lý chăm sóc da của SkinSync',
            description:
                'FE có section về sự kết hợp giữa thiên nhiên, khoa học và AI. Bản mobile này đưa nó thành một khối đọc gọn, dễ đọc bằng một tay.',
            icon: Icons.spa_outlined,
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: AspectRatio(
              aspectRatio: 1.42,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1760860991924-237b4160efbd'
                    '?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=900',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: SkinSyncGradients.brand,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          SkinSyncColors.espresso.withValues(alpha: .52),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Text(
                      'Botanical ingredients, lab-grade reasoning, AI routine builder.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...bullets.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BulletTile(data: item),
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
        tag: 'Công nghệ',
        title: 'AI phân tích sâu',
        description:
            'Computer Vision đọc nhiều chỉ số da trong vòng 30 giây và tóm tắt thành điểm da để bạn dễ theo dõi.',
        color: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
      ),
      _FeatureData(
        icon: Icons.track_changes_rounded,
        tag: 'Chính xác',
        title: 'Cá nhân hóa 100%',
        description:
            'Lộ trình được tạo theo loại da, mục tiêu, môi trường sống và thói quen hằng ngày.',
        color: const Color(0xFFF0FDF4),
        iconColor: const Color(0xFF16A34A),
      ),
      _FeatureData(
        icon: Icons.trending_up_rounded,
        tag: 'Thông minh',
        title: 'Theo dõi tiến trình',
        description:
            'Biểu đồ và lịch sử giúp so sánh thay đổi theo tuần/tháng, từ đó điều chỉnh routine.',
        color: const Color(0xFFFFF7ED),
        iconColor: const Color(0xFFEA580C),
      ),
      _FeatureData(
        icon: Icons.shield_outlined,
        tag: 'Bảo vệ',
        title: 'An toàn tuyệt đối',
        description:
            'Kiểm tra thành phần, cảnh báo xung đột và ưu tiên gợi ý lành tính cho da nhạy cảm.',
        color: const Color(0xFFFDF2F8),
        iconColor: const Color(0xFFDB2777),
      ),
    ];

    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            eyebrow: 'Tính năng nổi bật',
            title: 'Tại sao chọn SkinSync',
            description:
                'Nền tảng kết hợp AI với kiến thức chăm sóc da để đưa ra gợi ý có thể hành động ngay.',
            icon: Icons.bolt_outlined,
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

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepData(
        step: '01',
        icon: Icons.assignment_outlined,
        title: 'Khảo sát nhanh',
        description:
            'Trả lời các câu hỏi về lối sống, môi trường sống và mục tiêu làn da.',
        time: '~3 phút',
      ),
      _StepData(
        step: '02',
        icon: Icons.photo_camera_outlined,
        title: 'Tải ảnh & AI phân tích',
        description:
            'Upload ảnh tự chụp. AI sẽ quét, chấm điểm và nhận diện vấn đề chính.',
        time: '~30 giây',
      ),
      _StepData(
        step: '03',
        icon: Icons.auto_awesome_outlined,
        title: 'Nhận lộ trình riêng',
        description:
            'Routine sáng-tối, gợi ý sản phẩm và điều chỉnh liên tục theo tiến trình.',
        time: 'Liên tục',
      ),
    ];

    return _SectionShell(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            eyebrow: 'Chỉ 3 bước đơn giản',
            title: 'Quy trình hoạt động',
            description:
                'Từ lần đầu đăng ký đến lộ trình cá nhân hóa, mọi thứ được rút gọn cho mobile.',
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(height: 18),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _StepTile(step: step),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkinTypesSection extends StatelessWidget {
  const _SkinTypesSection();

  @override
  Widget build(BuildContext context) {
    final types = [
      _SkinTypeData(
        'Da dầu',
        'Kiểm soát bã nhờn tối ưu',
        Icons.water_drop_outlined,
        const Color(0xFFEFF6FF),
        const Color(0xFF2563EB),
      ),
      _SkinTypeData(
        'Da khô',
        'Phục hồi độ ẩm sâu',
        Icons.local_florist_outlined,
        const Color(0xFFFDF2F8),
        const Color(0xFFDB2777),
      ),
      _SkinTypeData(
        'Da hỗn hợp',
        'Cân bằng toàn diện',
        Icons.eco_outlined,
        const Color(0xFFF0FDF4),
        const Color(0xFF16A34A),
      ),
      _SkinTypeData(
        'Da nhạy cảm',
        'Bảo vệ nhe nhang',
        Icons.spa_outlined,
        const Color(0xFFFFF7ED),
        const Color(0xFFEA580C),
      ),
    ];

    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            eyebrow: 'Hỗ trợ mọi loại da',
            title: 'AI tìm giải pháp phù hợp',
            description:
                'Dù bạn thuộc nhóm da nào, SkinSync vẫn giữ gợi ý rõ ràng và có ưu tiên riêng.',
            icon: Icons.face_retouching_natural_outlined,
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: types.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.02,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (context, index) => _SkinTypeCard(data: types[index]),
          ),
        ],
      ),
    );
  }
}

class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection();

  @override
  Widget build(BuildContext context) {
    final testimonials = [
      _TestimonialData(
        name: 'Nguyễn Thị Lan',
        role: 'Kỹ sư phần mềm',
        skin: 'Da dầu mụn',
        imageUrl:
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=120&h=120&fit=crop&crop=face',
        quote:
            'Sau 6 tuần theo lộ trình AI, mụn đầu đen giảm rõ rệt. Gợi ý sản phẩm đúng như những gì da tôi cần.',
      ),
      _TestimonialData(
        name: 'Trần Minh Châu',
        role: 'Kiến trúc sư',
        skin: 'Da nhạy cảm',
        imageUrl:
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=120&h=120&fit=crop&crop=face',
        quote:
            'AI phân tích đúng điểm yếu của da nhạy cảm, routine ngắn gọn hơn nhưng an toàn hơn.',
      ),
      _TestimonialData(
        name: 'Phạm Thu Hương',
        role: 'Bác sĩ nội trú',
        skin: 'Da hỗn hợp',
        imageUrl:
            'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=120&h=120&fit=crop&crop=face',
        quote:
            'Đây là app đầu tiên giúp tôi thấy tiến trình chăm sóc da bằng số liệu rõ ràng.',
      ),
    ];

    return _SectionShell(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            eyebrow: 'Câu chuyện thực tế',
            title: 'Người dùng nói gì về SkinSync',
            description:
                'Hơn 50,000 người dùng đã tin tưởng SkinSync và theo dõi sự thay đổi của làn da mỗi ngày.',
            icon: Icons.star_rate_rounded,
          ),
          const SizedBox(height: 16),
          ...testimonials.map(
            (testimonial) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TestimonialCard(data: testimonial),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustBadgesSection extends StatelessWidget {
  const _TrustBadgesSection();

  @override
  Widget build(BuildContext context) {
    final badges = [
      _BadgeData(
        Icons.health_and_safety_outlined,
        'Kiểm duyệt bởi bác sĩ da liễu',
      ),
      _BadgeData(Icons.emoji_events_outlined, 'Healthtech 2025'),
      _BadgeData(Icons.verified_user_outlined, 'Bảo mật dữ liệu'),
      _BadgeData(Icons.groups_2_outlined, 'Cộng đồng 50K+'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: badges.map((badge) => _TrustBadge(data: badge)).toList(),
      ),
    );
  }
}

class _FinalCtaSection extends StatefulWidget {
  const _FinalCtaSection({required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  State<_FinalCtaSection> createState() => _FinalCtaSectionState();
}

class _FinalCtaSectionState extends State<_FinalCtaSection> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [SkinSyncColors.espresso, Color(0xFF3D2A14)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BrandLogo(
                  size: 44,
                  borderRadius: 15,
                  borderColor: Colors.white.withValues(alpha: .14),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Sẵn sàng cho làn da hoàn hảo?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Tham gia cùng cộng đồng SkinSync và bắt đầu phân tích miễn phí. Không cần thẻ ngân hàng, dữ liệu được bảo mật.',
              style: TextStyle(
                color: Color(0xFFD4B896),
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            _GradientButton(
              label: 'Bắt đầu phân tích da',
              icon: Icons.auto_awesome_rounded,
              onPressed: () => _showSoon(
                context,
                'Màn khảo sát/analysis sẽ được nối tiếp sau.',
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isLoggingOut ? null : _logout,
                icon: _isLoggingOut
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded),
                label: const Text('Đăng xuất'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE8D5B7),
                  side: BorderSide(color: Colors.white.withValues(alpha: .18)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            const Row(
              children: [
                Text(
                  'SkinSync',
                  style: TextStyle(
                    color: Color(0xFFE8D5B7),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Spacer(),
                Text(
                  '2026',
                  style: TextStyle(
                    color: Color(0xFF8B735E),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
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

class _SectionShell extends StatelessWidget {
  const _SectionShell({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color ?? Colors.transparent,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: SkinSyncColors.cream,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: SkinSyncColors.border.withValues(alpha: .65),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: SkinSyncColors.cocoa, size: 15),
              const SizedBox(width: 7),
              Text(
                eyebrow,
                style: const TextStyle(
                  color: SkinSyncColors.cocoa,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            color: SkinSyncColors.muted,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BulletData {
  const _BulletData({
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

class _BulletTile extends StatelessWidget {
  const _BulletTile({required this.data});

  final _BulletData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SkinSyncColors.linen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SkinSyncColors.border.withValues(alpha: .45)),
      ),
      child: Row(
        children: [
          _SoftIcon(
            icon: data.icon,
            color: data.color,
            iconColor: data.iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  data.description,
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

class _FeatureData {
  const _FeatureData({
    required this.icon,
    required this.tag,
    required this.title,
    required this.description,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final String tag;
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .025),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _SoftIcon(
            icon: feature.icon,
            color: feature.color,
            iconColor: feature.iconColor,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.tag,
                  style: const TextStyle(
                    color: SkinSyncColors.sand,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
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

class _StepData {
  const _StepData({
    required this.step,
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
  });

  final String step;
  final IconData icon;
  final String title;
  final String description;
  final String time;
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step});

  final _StepData step;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: SkinSyncGradients.brand,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(step.icon, color: Colors.white),
            ),
            Container(width: 2, height: 50, color: SkinSyncColors.border),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: SkinSyncColors.border.withValues(alpha: .45),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      step.step,
                      style: const TextStyle(
                        color: SkinSyncColors.sand,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: SkinSyncColors.cream,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        step.time,
                        style: const TextStyle(
                          color: SkinSyncColors.cocoa,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  step.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SkinTypeData {
  const _SkinTypeData(
    this.title,
    this.description,
    this.icon,
    this.color,
    this.iconColor,
  );

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color iconColor;
}

class _SkinTypeCard extends StatelessWidget {
  const _SkinTypeCard({required this.data});

  final _SkinTypeData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: data.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: data.iconColor, size: 28),
          const Spacer(),
          Text(data.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5),
          Text(
            data.description,
            style: const TextStyle(
              color: SkinSyncColors.muted,
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TestimonialData {
  const _TestimonialData({
    required this.name,
    required this.role,
    required this.skin,
    required this.imageUrl,
    required this.quote,
  });

  final String name;
  final String role;
  final String skin;
  final String imageUrl;
  final String quote;
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.data});

  final _TestimonialData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SkinSyncColors.linen,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SkinSyncColors.border.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
              Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
              Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
              Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
              Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"${data.quote}"',
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 13,
              height: 1.45,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Image.network(
                  data.imageUrl,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 42,
                    height: 42,
                    color: SkinSyncColors.cream,
                    child: const Icon(Icons.person_outline_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      data.role,
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
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: SkinSyncColors.cream,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  data.skin,
                  style: const TextStyle(
                    color: SkinSyncColors.cocoa,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeData {
  const _BadgeData(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.data});

  final _BadgeData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SkinSyncColors.border.withValues(alpha: .55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, color: SkinSyncColors.sand, size: 15),
          const SizedBox(width: 7),
          Text(
            data.label,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: iconColor),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
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
          onPressed: onPressed,
          icon: Icon(icon, size: 19),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
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
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: .92),
          foregroundColor: SkinSyncColors.cocoa,
          padding: EdgeInsets.zero,
          side: BorderSide(color: Colors.white.withValues(alpha: .55)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Icon(icon),
      ),
    );
  }
}

void _showSoon(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}
