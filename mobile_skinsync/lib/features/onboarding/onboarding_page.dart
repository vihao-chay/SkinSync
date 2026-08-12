import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/responsive/responsive.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
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
            constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(
                context,
                mobile: 520,
                tablet: 720,
                desktop: 860,
              ),
            ),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                children: [
                  _OnboardingHeader(
                    currentStep: state.currentStep,
                    onBack: () => _back(state),
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
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, OnboardingState state) async {
    final now = DateTime.now();
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BirthdayPickerSheet(
        initialDate:
            state.dateOfBirth ?? DateTime(now.year - 22, now.month, now.day),
        minDate: DateTime(1940),
        maxDate: now,
      ),
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
          await appState.refreshHome();
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
      Navigator.pushReplacementNamed(context, AppRoutes.onboardingIntro);
      return;
    }
    state.back();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.currentStep, required this.onBack});

  final int currentStep;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final canGoBack = currentStep > 0;
    final horizontalPadding = _onboardingHorizontalPadding(context);
    final topPadding = Responsive.responsiveValue<double>(
      context,
      mobileSmall: 18,
      mobile: 20,
      tablet: 24,
      desktop: 28,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        20,
      ),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: canGoBack ? onBack : onBack,
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.foreground.withValues(
                      alpha: canGoBack ? 1 : 0.45,
                    ),
                    size: 22,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: Responsive.responsiveValue<double>(
                    context,
                    mobileSmall: 92,
                    mobile: 104,
                    tablet: 120,
                    desktop: 136,
                  ),
                  child: LinearProgressIndicator(
                    value: (currentStep + 1) / OnboardingState.totalSteps,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: const Color(0xFFEADFD1),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 48,
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
      ),
    );
  }
}

double _onboardingHorizontalPadding(BuildContext context) {
  return Responsive.responsiveValue<double>(
    context,
    mobileSmall: 28,
    mobile: 28,
    tablet: 40,
    desktop: 48,
  );
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
        ? 'Select your date'
        : DateFormat('dd/MM/yyyy').format(state.dateOfBirth!);

    return _StepScrollView(
      eyebrow: 'Step 1',
      title: 'Tell SkinSync who you are.',
      child: Column(
        children: [
          _GlassPanel(
            child: Column(
              children: [
                _TextFieldBlock(
                  label: 'Display name',
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
                  icon: Icons.calendar_month_outlined,
                  onTap: onPickDate,
                  isPlaceholder: state.dateOfBirth == null,
                ),
                const SizedBox(height: 18),
                _GenderDropdown(
                  value: state.gender,
                  onChanged: state.setGender,
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
      child: Column(
        children: [
          _GlassPanel(
            child: Column(
              children: [
                _ChoiceWrap(
                  label: 'Skin type',
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
      child: Column(
        children: [
          _GlassPanel(
            child: Column(
              children: [
                _ChoiceWrap(
                  label: 'Monthly budget',
                  children: OnboardingState.budgetOptions.entries
                      .map(
                        (entry) => _ChoiceChipCard(
                          label:
                              '${entry.key} · ${_formatCurrency(entry.value)}',
                          selected: state.budgetLabel == entry.key,
                          onTap: () => state.setBudgetLabel(entry.key),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                _ChoiceWrap(
                  label: 'Primary goals',
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
  const _PhotoStep({required this.state, required this.onPickPhoto});

  final OnboardingState state;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    final photo = state.skinPhoto;

    return _StepScrollView(
      eyebrow: 'Step 5',
      title: 'Add a skin photo or skip for now.',
      child: Column(
        children: [
          _GlassPanel(
            padding: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: onPickPhoto,
                  child: SizedBox(
                    height: Responsive.responsiveValue<double>(
                      context,
                      mobileSmall: 350,
                      mobile: 378,
                      tablet: 408,
                      desktop: 430,
                    ),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(28, 32, 28, 22),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: AppColors.border,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: photo == null
                          ? _PhotoPlaceholder(onPickPhoto: onPickPhoto)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: Image.file(photo, fit: BoxFit.cover),
                            ),
                    ),
                  ),
                ),
                if (photo != null) ...[
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: onPickPhoto,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Replace photo'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => state.setPhoto(null),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
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
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.02)),
        ),
      ),
      child: Padding(
        padding: Responsive.responsivePadding(context, top: 14, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (errorMessage != null && errorMessage!.trim().isNotEmpty) ...[
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.error),
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
    required this.child,
  });

  final String eyebrow;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = _onboardingHorizontalPadding(context);

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primaryDark,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 3.2,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.heading,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 42),
          child,
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, this.padding});

  final Widget child;
  final double? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        padding ??
            Responsive.responsiveValue<double>(
              context,
              mobileSmall: 24,
              mobile: 26,
              tablet: 28,
              desktop: 30,
            ),
      ),
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
  const _TextFieldBlock({required this.label, required this.child});

  final String label;
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
      ],
    );
  }
}

class _ActionField extends StatelessWidget {
  const _ActionField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    required this.isPlaceholder,
  });

  final String label;
  final String value;
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
        Material(
          color: Colors.transparent,
          child: InkWell(
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
                  Icon(icon, color: AppColors.mutedText),
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GenderDropdown extends StatelessWidget {
  const _GenderDropdown({required this.value, required this.onChanged});

  final OnboardingGender? value;
  final ValueChanged<OnboardingGender> onChanged;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.foreground,
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_2_outlined, color: AppColors.mutedText),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<OnboardingGender>(
                    value: value,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(18),
                    dropdownColor: AppColors.surface,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.mutedText,
                    ),
                    hint: Text(
                      'Select gender',
                      style: textStyle?.copyWith(color: AppColors.mutedText),
                    ),
                    style: textStyle,
                    items: OnboardingGender.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(_genderLabel(item)),
                          ),
                        )
                        .toList(),
                    onChanged: (item) {
                      if (item != null) {
                        onChanged(item);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({required this.label, required this.children});

  final String label;
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
  const _PhotoPlaceholder({required this.onPickPhoto});

  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.camera_alt_outlined,
              color: AppColors.primaryDark,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 30),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Upload a clear skin photo',
            maxLines: 1,
            softWrap: false,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.heading,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          height: Responsive.responsiveValue<double>(
            context,
            mobileSmall: 116,
            mobile: 150,
            tablet: 166,
            desktop: 178,
          ),
        ),
        Center(
          child: FilledButton.icon(
            onPressed: onPickPhoto,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.primaryDark,
              minimumSize: const Size(154, 40),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            icon: const Icon(Icons.add_a_photo_outlined, size: 16),
            label: const Text('Choose photo'),
          ),
        ),
      ],
    );
  }
}

class _BirthdayPickerSheet extends StatefulWidget {
  const _BirthdayPickerSheet({
    required this.initialDate,
    required this.minDate,
    required this.maxDate,
  });

  final DateTime initialDate;
  final DateTime minDate;
  final DateTime maxDate;

  @override
  State<_BirthdayPickerSheet> createState() => _BirthdayPickerSheetState();
}

class _BirthdayPickerSheetState extends State<_BirthdayPickerSheet> {
  late final List<int> _years;
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;
  late int _year;
  late int _month;
  late int _day;

  static const _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _years = List.generate(
      widget.maxDate.year - widget.minDate.year + 1,
      (index) => widget.minDate.year + index,
    );
    final initial = _clampDate(widget.initialDate);
    _year = initial.year;
    _month = initial.month;
    _day = initial.day;
    _yearController = FixedExtentScrollController(
      initialItem: _years.indexOf(_year),
    );
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _dayController = FixedExtentScrollController(initialItem: _day - 1);
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final months = _availableMonths;
    final days = _availableDays;

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 58,
                child: Row(
                  children: [
                    const SizedBox(width: 48),
                    Expanded(
                      child: Center(
                        child: Text(
                          'SET BIRTHDAY',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppColors.foreground,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.mutedText,
                        iconSize: 22,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 40,
                          height: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: AppColors.border.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 216,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 42,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceStrong.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _BirthdayWheel(
                            controller: _yearController,
                            values: _years.map((value) => '$value').toList(),
                            selectedIndex: _years.indexOf(_year),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _year = _years[index];
                                _normalizeSelection();
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: _BirthdayWheel(
                            controller: _monthController,
                            values: months
                                .map((value) => _monthLabels[value - 1])
                                .toList(),
                            selectedIndex: months.indexOf(_month),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _month = months[index];
                                _normalizeSelection();
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: _BirthdayWheel(
                            controller: _dayController,
                            values: days.map((value) => '$value').toList(),
                            selectedIndex: days.indexOf(_day),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _day = days[index];
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.heading,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context, DateTime(_year, _month, _day));
                    },
                    child: const Text('SUBMIT'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<int> get _availableMonths {
    final lastMonth = _year == widget.maxDate.year ? widget.maxDate.month : 12;
    return List.generate(lastMonth, (index) => index + 1);
  }

  List<int> get _availableDays {
    final monthDays = DateUtils.getDaysInMonth(_year, _month);
    final lastDay =
        _year == widget.maxDate.year && _month == widget.maxDate.month
        ? widget.maxDate.day
        : monthDays;
    return List.generate(lastDay, (index) => index + 1);
  }

  DateTime _clampDate(DateTime value) {
    if (value.isBefore(widget.minDate)) {
      return widget.minDate;
    }
    if (value.isAfter(widget.maxDate)) {
      return widget.maxDate;
    }
    return value;
  }

  void _normalizeSelection() {
    final months = _availableMonths;
    if (!months.contains(_month)) {
      _month = months.last;
      _monthController.jumpToItem(_month - 1);
    }

    final days = _availableDays;
    if (!days.contains(_day)) {
      _day = days.last;
      _dayController.jumpToItem(_day - 1);
    }
  }
}

class _BirthdayWheel extends StatelessWidget {
  const _BirthdayWheel({
    required this.controller,
    required this.values,
    required this.selectedIndex,
    required this.onSelectedItemChanged,
  });

  final FixedExtentScrollController controller;
  final List<String> values;
  final int selectedIndex;
  final ValueChanged<int> onSelectedItemChanged;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 42,
      diameterRatio: 1.35,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelectedItemChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: values.length,
        builder: (context, index) {
          final selected = index == selectedIndex;
          return Center(
            child: Text(
              values[index],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected ? AppColors.foreground : AppColors.mutedText,
                fontSize: selected ? 20 : 14,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          );
        },
      ),
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
