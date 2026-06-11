import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
    final appState = context.read<AppState>();
    return ChangeNotifierProvider(
      create: (_) => OnboardingState(
        initialDisplayName: appState.onboardingDisplayNameSeed,
        initialProfile: appState.profile,
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
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _pageController.dispose();
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
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                _OnboardingHeader(
                  currentStep: state.currentStep,
                  onBack: () => _back(state),
                  onLogout: () => _logout(context),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _BasicInfoStep(
                        state: state,
                        nameController: _nameController,
                        onPickDate: () => _pickDate(context, state),
                      ),
                      _SkinProfileStep(state: state),
                      _RoutineStep(state: state),
                      _BudgetGoalsStep(state: state),
                      _PhotoStep(
                        state: state,
                        onPickPhoto: () => _pickPhoto(state),
                      ),
                    ],
                  ),
                ),
                _BottomActionBar(
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

  Future<void> _pickDate(BuildContext context, OnboardingState state) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          state.dateOfBirth ?? DateTime(now.year - 22, now.month, now.day),
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

  Future<void> _pickPhoto(OnboardingState state) async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (image == null) {
      return;
    }
    state.setPhoto(File(image.path));
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
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    state.setSubmitting(true);
    final appState = context.read<AppState>();
    try {
      await appState.submitOnboarding(state.toPayload());

      try {
        final photo = state.skinPhoto;
        if (photo != null) {
          await appState.analyzeSkin(photo);
        } else {
          await appState.generateRoutine(budgetMax: state.monthlyBudget);
        }
      } catch (_) {
        appState.clearError();
        await appState.refreshHome();
      }

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
            content: Text(
              'We could not finish onboarding right now. Please try again.',
            ),
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
    _pageController.previousPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _logout(BuildContext context) async {
    final appState = context.read<AppState>();
    await appState.logout();
    if (!context.mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.currentStep,
    required this.onBack,
    required this.onLogout,
  });

  final int currentStep;
  final VoidCallback onBack;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final canGoBack = currentStep > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          if (canGoBack)
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.foreground,
              ),
            )
          else
            TextButton(
              onPressed: onLogout,
              child: const Text('Sign out'),
            ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandLogo(size: 24, radius: 8, showShadow: false),
              const SizedBox(width: 8),
              Text(
                'SkinSync',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 72,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${currentStep + 1}/${OnboardingState.totalSteps}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BasicInfoStep extends StatelessWidget {
  const _BasicInfoStep({
    required this.state,
    required this.nameController,
    required this.onPickDate,
  });

  final OnboardingState state;
  final TextEditingController nameController;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final dateLabel = state.dateOfBirth == null
        ? 'Select your date of birth'
        : DateFormat('dd/MM/yyyy').format(state.dateOfBirth!);

    return _StepScrollView(
      eyebrow: 'Step 1',
      title: 'Tell SkinSync who you are.',
      subtitle:
          'Start with the basics so your skincare journey feels personal from the first dashboard refresh.',
      child: Column(
        children: [
          _GlassPanel(
            child: Column(
              children: [
                _TextFieldBlock(
                  label: 'Display name',
                  helper: 'This name is used in greetings and profile summaries.',
                  child: TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    onChanged: state.setDisplayName,
                    decoration: const InputDecoration(
                      hintText: 'Example: Kien',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _ActionField(
                  label: 'Date of birth',
                  value: dateLabel,
                  helper: 'Age helps SkinSync fine-tune context for routine planning.',
                  icon: Icons.calendar_month_outlined,
                  onTap: onPickDate,
                  isPlaceholder: state.dateOfBirth == null,
                ),
                const SizedBox(height: 18),
                _ChoiceWrap(
                  label: 'Gender',
                  helper: 'Choose the option that feels right for you.',
                  children: OnboardingGender.values
                      .map(
                        (item) => _ChoiceChipCard(
                          label: _genderLabel(item),
                          selected: state.gender == item,
                          onTap: () => state.setGender(item),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkinProfileStep extends StatelessWidget {
  const _SkinProfileStep({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    return _StepScrollView(
      eyebrow: 'Step 2',
      title: 'Describe your skin profile.',
      subtitle:
          'Pick your skin type and the concerns you want SkinSync to pay attention to first.',
      child: Column(
        children: [
          _GlassPanel(
            child: Column(
              children: [
                _ChoiceWrap(
                  label: 'Skin type',
                  helper: 'This helps tailor the routine structure and product categories.',
                  children: OnboardingState.skinTypeOptions
                      .map(
                        (item) => _ChoiceChipCard(
                          label: item,
                          selected: state.skinType == item,
                          onTap: () => state.setSkinType(item),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                _ChoiceWrap(
                  label: 'Main concerns',
                  helper: 'Choose any concerns you want the dashboard and AI to prioritize.',
                  children: OnboardingState.concernOptions
                      .map(
                        (item) => _ChoiceChipCard(
                          label: item,
                          selected: state.concerns.contains(item),
                          onTap: () => state.toggleConcern(item),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineStep extends StatelessWidget {
  const _RoutineStep({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    return _StepScrollView(
      eyebrow: 'Step 3',
      title: 'How established is your current routine?',
      subtitle:
          'This lets SkinSync generate an initial plan that feels realistic instead of overwhelming.',
      child: Column(
        children: [
          _GlassPanel(
            child: Column(
              children: OnboardingState.routineOptions
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SelectableTile(
                        title: item,
                        subtitle: _routineSubtitle(item),
                        selected: state.routineLevel == item,
                        onTap: () => state.setRoutineLevel(item),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetGoalsStep extends StatelessWidget {
  const _BudgetGoalsStep({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    return _StepScrollView(
      eyebrow: 'Step 4',
      title: 'Set your budget and skincare goals.',
      subtitle:
          'SkinSync will use this to keep recommendations aligned with your priorities and spend comfort.',
      child: Column(
        children: [
          _GlassPanel(
            child: Column(
              children: [
                _ChoiceWrap(
                  label: 'Monthly budget',
                  helper: 'Choose the level that feels sustainable for your routine.',
                  children: OnboardingState.budgetOptions.entries
                      .map(
                        (entry) => _ChoiceChipCard(
                          label: '${entry.key} · ${_formatCurrency(entry.value)}',
                          selected: state.budgetLabel == entry.key,
                          onTap: () => state.setBudgetLabel(entry.key),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                _ChoiceWrap(
                  label: 'Primary goals',
                  helper: 'Pick the outcomes you care about most right now.',
                  children: OnboardingState.goalOptions
                      .map(
                        (item) => _ChoiceChipCard(
                          label: item,
                          selected: state.goals.contains(item),
                          onTap: () => state.toggleGoal(item),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoStep extends StatelessWidget {
  const _PhotoStep({
    required this.state,
    required this.onPickPhoto,
  });

  final OnboardingState state;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    final photo = state.skinPhoto;

    return _StepScrollView(
      eyebrow: 'Step 5',
      title: 'Add a skin photo or skip for now.',
      subtitle:
          'A photo helps unlock AI analysis immediately. You can still finish onboarding without one and scan later from Dashboard or AI Hub.',
      child: Column(
        children: [
          _GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: onPickPhoto,
                  child: Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: AppColors.border,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: photo == null
                        ? const _PhotoPlaceholder()
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: Image.file(photo, fit: BoxFit.cover),
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: onPickPhoto,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(photo == null ? 'Choose photo' : 'Replace photo'),
                    ),
                    if (photo != null)
                      OutlinedButton.icon(
                        onPressed: () => state.setPhoto(null),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Remove'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (errorMessage != null && errorMessage!.trim().isNotEmpty) ...[
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: state.isSubmitting ? null : onPressed,
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isFinalStep ? 'Finish onboarding' : 'Continue'),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isFinalStep
                  ? 'Skipping the photo is okay. You can run your first scan later.'
                  : 'SkinSync will save your progress and personalize the next step.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primaryDark.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepScrollView extends StatelessWidget {
  const _StepScrollView({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (context.watch<OnboardingState>().currentStep + 1) /
                OnboardingState.totalSteps,
            minHeight: 6,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: const Color(0xFFEADFD1),
            valueColor: const AlwaysStoppedAnimation(AppColors.primaryDark),
          ),
          const SizedBox(height: 20),
          Text(
            eyebrow,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.heading,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TextFieldBlock extends StatelessWidget {
  const _TextFieldBlock({
    required this.label,
    required this.helper,
    required this.child,
  });

  final String label;
  final String helper;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 8),
        Text(
          helper,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.mutedText,
          ),
        ),
      ],
    );
  }
}

class _ActionField extends StatelessWidget {
  const _ActionField({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.onTap,
    required this.isPlaceholder,
  });

  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isPlaceholder
                          ? AppColors.mutedText
                          : AppColors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primaryDark,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          helper,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.mutedText,
          ),
        ),
      ],
    );
  }
}

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({
    required this.label,
    required this.helper,
    required this.children,
  });

  final String label;
  final String helper;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          helper,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.mutedText,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: children),
      ],
    );
  }
}

class _ChoiceChipCard extends StatelessWidget {
  const _ChoiceChipCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.secondary : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primaryDark : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceStrong : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primaryDark : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.heading,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: AppColors.primaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.camera_alt_outlined,
            color: AppColors.primaryDark,
            size: 30,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Upload a clear skin photo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.heading,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Natural light and a makeup-free close-up help the AI produce a better first analysis.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.mutedText,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

String _genderLabel(OnboardingGender gender) {
  switch (gender) {
    case OnboardingGender.male:
      return 'Male';
    case OnboardingGender.female:
      return 'Female';
    case OnboardingGender.other:
      return 'Other';
    case OnboardingGender.preferNotToSay:
      return 'Prefer not to say';
  }
}

String _routineSubtitle(String label) {
  switch (label) {
    case 'Beginner':
      return 'I want something simple with only essential steps.';
    case 'Balanced':
      return 'I already do some skincare and want a sustainable routine.';
    case 'Advanced':
      return 'I am comfortable with actives and a more structured regimen.';
    case 'Minimal':
      return 'I want the fewest possible steps with clear impact.';
    default:
      return 'SkinSync will adapt recommendations to this level.';
  }
}

String _formatCurrency(int value) {
  return NumberFormat.decimalPattern().format(value);
}
