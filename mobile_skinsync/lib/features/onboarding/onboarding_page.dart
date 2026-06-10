import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/responsive_container.dart';
import 'onboarding_state.dart';
import 'widgets/choice_tiles.dart';
import 'widgets/date_picker_field.dart';
import 'widgets/onboarding_layout.dart';
import 'widgets/primary_button.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingState(),
      child: const _OnboardingBody(),
    );
  }
}

class _OnboardingBody extends StatefulWidget {
  const _OnboardingBody();

  @override
  State<_OnboardingBody> createState() => _OnboardingBodyState();
}

class _OnboardingBodyState extends State<_OnboardingBody> {
  final PageController _controller = PageController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingState>();
    final appState = context.read<AppState>();

    if (_nameController.text.isEmpty && state.displayName.isNotEmpty) {
      _nameController.text = state.displayName;
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: ResponsiveContainer(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _introStep(),
                    _nameStep(state),
                    _dobStep(state),
                    _genderStep(state),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  0,
                  AppSpacing.pagePadding,
                  AppSpacing.pagePadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (appState.errorMessage != null) ...[
                      Text(
                        appState.errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
                      ),
                      const SizedBox(height: 8),
                    ],
                    PrimaryButton(
                      label: state.currentStep == OnboardingState.totalSteps - 1 ? 'Hoàn tất' : 'Tiếp tục',
                      isLoading: state.isSubmitting || appState.isBusy,
                      onPressed: () => _next(context, state),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _introStep() {
    return OnboardingLayout(
      progress: 1 / OnboardingState.totalSteps,
      title: 'Bạn đã thực sự hiểu làn da của mình chưa?',
      subtitle: 'Hãy bắt đầu hành trình mới để SkinSync hiểu bạn hơn và cá nhân hoá routine phù hợp.',
      onBack: null,
      child: const SizedBox.shrink(),
      bottomBar: const SizedBox.shrink(),
    );
  }

  Widget _nameStep(OnboardingState state) {
    return OnboardingLayout(
      progress: 2 / OnboardingState.totalSteps,
      title: 'Bạn muốn SkinSync gọi bạn là gì?',
      subtitle: 'Tên hiển thị giúp app cá nhân hoá lời chào và trải nghiệm của bạn.',
      onBack: () {
        state.back();
        _controller.previousPage(duration: const Duration(milliseconds: 240), curve: Curves.easeOutCubic);
      },
      child: PremiumCard(
        child: AppTextField(
          label: 'Tên hiển thị',
          hint: 'Nhập tên của bạn',
          controller: _nameController,
          autofocus: true,
          onChanged: (value) {
            state.displayName = value;
            state.notifyListeners();
          },
        ),
      ),
      bottomBar: const SizedBox.shrink(),
    );
  }

  Widget _dobStep(OnboardingState state) {
    return OnboardingLayout(
      progress: 3 / OnboardingState.totalSteps,
      title: '${state.displayName.isNotEmpty ? state.displayName : 'Bạn'}, ngày sinh của bạn là ngày nào thế?',
      subtitle: 'Thông tin này giúp chúng tôi hiểu rõ hơn về làn da của bạn.',
      onBack: () {
        state.back();
        _controller.previousPage(duration: const Duration(milliseconds: 240), curve: Curves.easeOutCubic);
      },
      child: DatePickerField(
        label: 'Ngày sinh',
        value: state.dateOfBirth,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: state.dateOfBirth ?? DateTime(2000, 1, 1),
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            state.dateOfBirth = picked;
            state.notifyListeners();
          }
        },
      ),
      bottomBar: const SizedBox.shrink(),
    );
  }

  Widget _genderStep(OnboardingState state) {
    return OnboardingLayout(
      progress: 1,
      title: 'Hello ${state.displayName.isNotEmpty ? state.displayName : 'bạn'}, giới tính của bạn là gì?',
      subtitle: 'Thông tin này giúp chúng tôi điều chỉnh thói quen để phù hợp hơn với bạn.',
      onBack: () {
        state.back();
        _controller.previousPage(duration: const Duration(milliseconds: 240), curve: Curves.easeOutCubic);
      },
      child: Column(
        children: [
          for (final item in OnboardingGender.values) ...[
            SingleChoiceTile(
              title: switch (item) {
                OnboardingGender.male => 'Nam',
                OnboardingGender.female => 'Nữ',
                OnboardingGender.other => 'Khác',
                OnboardingGender.preferNotToSay => 'Không muốn trả lời',
              },
              selected: state.gender == item,
              onTap: () {
                state.gender = item;
                state.notifyListeners();
              },
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
      bottomBar: const SizedBox.shrink(),
    );
  }

  Future<void> _next(BuildContext context, OnboardingState state) async {
    if (!state.canContinue) {
      final message = state.validationMessage ?? 'Vui lòng hoàn thành bước này.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    if (state.currentStep < OnboardingState.totalSteps - 1) {
      state.next();
      await _controller.nextPage(duration: const Duration(milliseconds: 240), curve: Curves.easeOutCubic);
      return;
    }

    state.isSubmitting = true;
    state.notifyListeners();
    try {
      final payload = state.toPayload();
      await context.read<AppState>().submitOnboarding(payload);
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.dashboard, (route) => false);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể lưu thông tin. Vui lòng thử lại.')),
      );
    } finally {
      state.isSubmitting = false;
      state.notifyListeners();
    }
  }
}
