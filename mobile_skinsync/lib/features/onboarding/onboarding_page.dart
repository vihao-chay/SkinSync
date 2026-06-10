import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import 'onboarding_state.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => OnboardingState(
        initialDisplayName: context.read<AppState>().onboardingDisplayNameSeed,
      ),
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
    final appState = context.watch<AppState>();

    if (_nameController.text != state.displayName) {
      _nameController.value = TextEditingValue(
        text: state.displayName,
        selection: TextSelection.collapsed(offset: state.displayName.length),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6EF),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                _OnboardingHeader(
                  currentStep: state.currentStep,
                  onClose: () => _closeOnboarding(context),
                  onBack: () => _back(state),
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _introStep(context),
                      _nameStep(context, state),
                      _dateOfBirthStep(context, state),
                      _genderStep(context, state),
                    ],
                  ),
                ),
                _BottomAction(
                  state: state,
                  errorMessage: appState.errorMessage,
                  onPressed: () => _next(context, state),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _introStep(BuildContext context) {
    return _ScrollStep(
      child: Column(
        children: [
          const SizedBox(height: 6),
          const _ProgressBar(progress: 0.33),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: _softCardDecoration(radius: 28),
            child: Column(
              children: [
                const _IntroStillLife(),
                const SizedBox(height: 24),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Have you truly\nunderstood your\n'),
                      TextSpan(
                        text: 'skin',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              color: AppColors.primaryDark,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const TextSpan(text: '?'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppColors.foreground,
                    fontSize: 34,
                    height: 1.12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Start a short journey so SkinSync can understand your skin and personalize your routine.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.foreground.withValues(alpha: 0.76),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                const Row(
                  children: [
                    Expanded(
                      child: _FeatureTile(
                        icon: Icons.science_outlined,
                        title: 'AI Analysis',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _FeatureTile(
                        icon: Icons.spa_outlined,
                        title: 'Ingredient\nIntelligence',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const _IntroPagerLabel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameStep(BuildContext context, OnboardingState state) {
    return _ScrollStep(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepMeta(
            leading: 'Step 1 of 3',
            trailing: 'Welcome',
            progress: 1 / 3,
          ),
          const SizedBox(height: 34),
          Text(
            'What would you\nlike SkinSync to\ncall you?',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 37,
              height: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Your display name helps personalize greetings and your experience.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.foreground.withValues(alpha: 0.78),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 44),
          _InputPanel(
            label: 'Display Name',
            helper: 'Example: "Emily" or "My skincare name"',
            child: TextField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: state.setDisplayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.foreground,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: 'Example: Emily',
                prefixIcon: Icon(Icons.account_circle_outlined, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 44),
          const Center(child: _LotusSeal()),
          const SizedBox(height: 18),
          Center(
            child: Text(
              '"Beauty is the harmony of nature\nand precise science"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primaryDark.withValues(alpha: 0.76),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateOfBirthStep(BuildContext context, OnboardingState state) {
    final formattedDate = state.dateOfBirth == null
        ? 'dd/mm/yyyy'
        : DateFormat('dd/MM/yyyy').format(state.dateOfBirth!);

    return _ScrollStep(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepMeta(
            leading: 'Step 2 of 3',
            trailing: '66% Complete',
            progress: 2 / 3,
          ),
          const SizedBox(height: 34),
          Text(
            'What is your date of birth?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.foreground,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'DMSans',
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'This information helps us understand your skin more accurately.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.foreground.withValues(alpha: 0.82),
              height: 1.65,
            ),
          ),
          const SizedBox(height: 38),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: _softCardDecoration(radius: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date of Birth',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _pickDate(context, state),
                  child: Container(
                    height: 58,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBF6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE7D7C1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 20,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: state.dateOfBirth == null
                                    ? AppColors.mutedText
                                    : AppColors.foreground,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6EFE6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_rounded,
                        color: AppColors.primaryDark,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'AI care insights work better when age helps estimate skin changes and routine needs.',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.primaryDark,
                                height: 1.45,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderStep(BuildContext context, OnboardingState state) {
    return _ScrollStep(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _StepMeta(
            leading: 'Step 3 of 3',
            trailing: 'Complete Profile',
            progress: 1,
          ),
          const SizedBox(height: 28),
          Text(
            'Hello, what is\nyour gender?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.foreground,
              fontSize: 30,
              height: 1.12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This information helps us adjust routines to better fit you.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.foreground.withValues(alpha: 0.78),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: _softCardDecoration(radius: 24),
            child: Column(
              children: [
                _GenderOption(
                  icon: Icons.male_rounded,
                  title: 'Male',
                  subtitle: 'Man',
                  selected: state.gender == OnboardingGender.male,
                  onTap: () => state.setGender(OnboardingGender.male),
                ),
                _GenderOption(
                  icon: Icons.female_rounded,
                  title: 'Female',
                  subtitle: 'Woman',
                  selected: state.gender == OnboardingGender.female,
                  onTap: () => state.setGender(OnboardingGender.female),
                ),
                _GenderOption(
                  icon: Icons.groups_2_outlined,
                  title: 'Other',
                  subtitle: 'Another identity',
                  selected: state.gender == OnboardingGender.other,
                  onTap: () => state.setGender(OnboardingGender.other),
                ),
                _GenderOption(
                  icon: Icons.visibility_off_outlined,
                  title: 'Prefer not to say',
                  subtitle: 'Skip this question',
                  selected: state.gender == OnboardingGender.preferNotToSay,
                  onTap: () => state.setGender(OnboardingGender.preferNotToSay),
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, OnboardingState state) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          state.dateOfBirth ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryDark,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.foreground,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      state.setDateOfBirth(picked);
    }
  }

  Future<void> _next(BuildContext context, OnboardingState state) async {
    if (!state.canContinue) {
      final message =
          state.validationMessage ?? 'Please complete this step first.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    if (state.currentStep < OnboardingState.totalSteps - 1) {
      state.next();
      await _controller.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    state.setSubmitting(true);
    try {
      await context.read<AppState>().submitOnboarding(state.toPayload());
      if (!context.mounted) {
        return;
      }
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
        (route) => false,
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('We could not save your profile. Please try again.'),
          ),
        );
    } finally {
      state.setSubmitting(false);
    }
  }

  void _back(OnboardingState state) {
    if (state.currentStep == 0) {
      return;
    }
    state.back();
    _controller.previousPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _closeOnboarding(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.dashboard,
      (route) => false,
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.currentStep,
    required this.onClose,
    required this.onBack,
  });

  final int currentStep;
  final VoidCallback onClose;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final canGoBack = currentStep > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: SizedBox(
        height: 42,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: canGoBack ? 'Back' : 'Close',
                onPressed: canGoBack ? onBack : onClose,
                icon: Icon(
                  canGoBack ? Icons.arrow_back_rounded : Icons.close_rounded,
                  size: 20,
                  color: AppColors.foreground,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandLogo(size: 24, radius: 7, showShadow: false),
                const SizedBox(width: 8),
                Text(
                  'SkinSync',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScrollStep extends StatelessWidget {
  const _ScrollStep({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
      child: child,
    );
  }
}

class _StepMeta extends StatelessWidget {
  const _StepMeta({
    required this.leading,
    required this.trailing,
    required this.progress,
  });

  final String leading;
  final String trailing;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              leading,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              trailing,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ProgressBar(progress: progress),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 5,
        child: LinearProgressIndicator(
          value: progress.clamp(0, 1),
          backgroundColor: const Color(0xFFF0E8DD),
          valueColor: const AlwaysStoppedAnimation(Color(0xFFA6815C)),
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.state,
    required this.errorMessage,
    required this.onPressed,
  });

  final OnboardingState state;
  final String? errorMessage;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isFinalStep = state.currentStep == OnboardingState.totalSteps - 1;
    final label = switch (state.currentStep) {
      0 => 'Start Discovery',
      3 => 'Complete',
      _ => 'Continue',
    };
    final footer = switch (state.currentStep) {
      0 => 'Only 3 quick steps to personalize your routine',
      3 => 'Secured by SkinSync AI Analysis',
      _ => 'You can change this later in settings.',
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6EF),
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (errorMessage != null) ...[
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: state.isSubmitting ? null : onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF87663D),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(
                    0xFF87663D,
                  ).withValues(alpha: 0.55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label),
                          const SizedBox(width: 10),
                          Icon(
                            isFinalStep
                                ? Icons.arrow_forward_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              footer,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primaryDark.withValues(alpha: 0.72),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputPanel extends StatelessWidget {
  const _InputPanel({
    required this.label,
    required this.child,
    required this.helper,
  });

  final String label;
  final Widget child;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: _softCardDecoration(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          child,
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppColors.mutedText,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  helper,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.mutedText,
                    fontSize: 10,
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

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 20),
          const SizedBox(height: 9),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.foreground,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroPagerLabel extends StatelessWidget {
  const _IntroPagerLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(active: true),
        const SizedBox(width: 5),
        _dot(active: false),
        const SizedBox(width: 13),
        Text(
          'SKIN DISCOVERY QUIZ',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.primaryDark.withValues(alpha: 0.62),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _dot({required bool active}) {
    return Container(
      width: active ? 12 : 5,
      height: 5,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFA6815C) : const Color(0xFFD8C8B4),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _LotusSeal extends StatelessWidget {
  const _LotusSeal();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF8F0E7),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Container(
        width: 58,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFBF6EF),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        child: const Icon(
          Icons.local_florist_outlined,
          color: AppColors.primaryDark,
          size: 24,
        ),
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFBF6EF) : Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? const Color(0xFFA6815C)
                  : AppColors.border.withValues(alpha: 0.68),
              width: selected ? 1.3 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryDark, size: 21),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.foreground,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.mutedText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.primaryDark : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? AppColors.primaryDark
                        : AppColors.border.withValues(alpha: 0.95),
                    width: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroStillLife extends StatelessWidget {
  const _IntroStillLife();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: double.infinity,
        height: 128,
        child: CustomPaint(painter: _StillLifePainter()),
      ),
    );
  }
}

class _StillLifePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF4E9D8), Color(0xFFEFE4D2), Color(0xFFFDFBF7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final shadow = Paint()
      ..color = const Color(0xFF6F5C46).withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.54, size.height * 0.82),
        width: size.width * 0.78,
        height: size.height * 0.18,
      ),
      shadow,
    );

    final leafPaint = Paint()
      ..color = const Color(0xFF3C7A49)
      ..style = PaintingStyle.fill;
    final stemPaint = Paint()
      ..color = const Color(0xFF2F6040)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final stemStart = Offset(size.width * 0.14, size.height * 0.73);
    final stemEnd = Offset(size.width * 0.41, size.height * 0.52);
    canvas.drawLine(stemStart, stemEnd, stemPaint);
    for (var i = 0; i < 5; i++) {
      final x = size.width * (0.19 + i * 0.045);
      final y = size.height * (0.69 - i * 0.035);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(i.isEven ? -0.55 : 0.55);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 0.085,
          height: size.height * 0.12,
        ),
        leafPaint,
      );
      canvas.restore();
    }

    final bottleX = size.width * 0.29;
    final bottleTop = size.height * 0.28;
    final bottlePaint = Paint()
      ..color = const Color(0xFFC07A2D).withValues(alpha: 0.88);
    final glassPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bottleX, bottleTop, 34, 70),
        const Radius.circular(8),
      ),
      bottlePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bottleX, bottleTop, 34, 70),
        const Radius.circular(8),
      ),
      glassPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(bottleX + 10, bottleTop - 12, 14, 14),
      Paint()..color = const Color(0xFF65492D),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bottleX + 5, bottleTop - 25, 24, 14),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF3B2A1D),
    );
    canvas.drawLine(
      Offset(bottleX + 19, bottleTop - 25),
      Offset(bottleX + 19, bottleTop - 54),
      Paint()
        ..color = const Color(0xFF3B2A1D)
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );

    final cupRect = Rect.fromLTWH(
      size.width * 0.55,
      size.height * 0.27,
      size.width * 0.25,
      size.height * 0.5,
    );
    final cupPath = Path()
      ..moveTo(cupRect.left + 8, cupRect.top)
      ..lineTo(cupRect.right - 8, cupRect.top)
      ..lineTo(cupRect.right - 16, cupRect.bottom)
      ..lineTo(cupRect.left + 16, cupRect.bottom)
      ..close();
    canvas.drawPath(
      cupPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      cupPath,
      Paint()
        ..color = const Color(0xFF8E806C).withValues(alpha: 0.48)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cupRect.left + 14, cupRect.bottom - 22)
        ..lineTo(cupRect.right - 16, cupRect.bottom - 30)
        ..lineTo(cupRect.right - 18, cupRect.bottom)
        ..lineTo(cupRect.left + 16, cupRect.bottom)
        ..close(),
      Paint()..color = const Color(0xFFC4B05E).withValues(alpha: 0.72),
    );

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.64, size.height * 0.32),
      Offset(size.width * 0.62, size.height * 0.68),
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

BoxDecoration _softCardDecoration({required double radius}) {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: 0.96),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
    boxShadow: [
      BoxShadow(
        color: AppColors.primaryDark.withValues(alpha: 0.08),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ],
  );
}
