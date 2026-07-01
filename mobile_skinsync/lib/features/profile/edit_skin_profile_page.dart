import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_locale.dart';
import '../../core/responsive/responsive.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../onboarding/onboarding_state.dart';

class EditSkinProfilePage extends StatefulWidget {
  const EditSkinProfilePage({super.key});

  @override
  State<EditSkinProfilePage> createState() => _EditSkinProfilePageState();
}

class _EditSkinProfilePageState extends State<EditSkinProfilePage> {
  bool _hasSeeded = false;
  DateTime? _dateOfBirth;
  OnboardingGender? _gender;
  String? _skinType;
  String? _routinePreference;
  String? _budgetLabel;
  final Set<String> _concerns = <String>{};
  final Set<String> _goals = <String>{};
  double _sensitivity = 5;
  bool _hasSensitivity = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = context.read<AppState>().profile;
    if (_hasSeeded || profile == null) {
      return;
    }
    _hasSeeded = true;

    _dateOfBirth = _tryParseDate(profile.dateOfBirth);
    _gender = _parseGender(profile.gender);
    _skinType = profile.skinType;
    _routinePreference = profile.currentRoutineLevel;
    _budgetLabel = profile.budgetLabel;
    _concerns
      ..clear()
      ..addAll(profile.concerns.where((item) => item.trim().isNotEmpty));
    _goals
      ..clear()
      ..addAll(
        (profile.goals.isNotEmpty ? profile.goals : profile.skinGoals).where(
          (item) => item.trim().isNotEmpty,
        ),
      );
    if (profile.sensitivityLevel != null) {
      _hasSensitivity = true;
      _sensitivity = profile.sensitivityLevel!.toDouble();
      _sensitivity = _sensitivity.clamp(1.0, 10.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final appState = context.watch<AppState>();
    final profile = appState.profile;
    final textTheme = Theme.of(context).textTheme;
    final concernOptions = _mergedOptions(
      OnboardingState.concernOptions,
      _concerns,
    );
    final goalOptions = _mergedOptions(OnboardingState.goalOptions, _goals);

    return AppScaffold(
      title: locale.tr('edit_profile_title'),
      subtitle: locale.tr('edit_profile_subtitle'),
      onRefresh: appState.refreshProfileState,
      compactHeader: true,
      showBackButton: true,
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          Responsive.responsiveHorizontalPadding(context),
          0,
          Responsive.responsiveHorizontalPadding(context),
          Responsive.contentBottomSpacing(context, extra: 20),
        ),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.tr('edit_profile_skin_basics'),
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _TwoColumnWrap(
                  children: [
                    _SelectionField(
                      label: locale.tr('profile_skin_type'),
                      value: _friendlyText(_skinType, locale),
                      onTap: () => _showChoiceSheet(
                        context,
                        title: locale.tr('profile_skin_type'),
                        options: _mergedOptions(
                          OnboardingState.skinTypeOptions,
                          _skinType == null ? const <String>[] : [_skinType!],
                        ),
                        selected: _skinType,
                        onSelected: (value) =>
                            setState(() => _skinType = value),
                      ),
                    ),
                    _SelectionField(
                      label: locale.tr('profile_gender'),
                      value: _genderLabel(_gender, locale),
                      onTap: () => _showChoiceSheet(
                        context,
                        title: locale.tr('profile_gender'),
                        options: [
                          locale.tr('edit_profile_gender_male'),
                          locale.tr('edit_profile_gender_female'),
                          locale.tr('edit_profile_gender_other'),
                          locale.tr('edit_profile_gender_prefer_not_to_say'),
                        ],
                        selected: _genderLabel(_gender, locale),
                        onSelected: (value) => setState(
                          () => _gender = _genderFromLabel(value, locale),
                        ),
                      ),
                    ),
                    _SelectionField(
                      label: locale.tr('edit_profile_date_of_birth'),
                      value: _dateOfBirth == null
                          ? locale.tr('profile_not_provided')
                          : DateFormat('dd/MM/yyyy').format(_dateOfBirth!),
                      onTap: _pickDateOfBirth,
                    ),
                    _SelectionField(
                      label: locale.tr('profile_budget'),
                      value: _friendlyText(_budgetLabel, locale),
                      onTap: () => _showChoiceSheet(
                        context,
                        title: locale.tr('profile_budget'),
                        options: _mergedOptions(
                          OnboardingState.budgetOptions.keys,
                          _budgetLabel == null
                              ? const <String>[]
                              : [_budgetLabel!],
                        ),
                        selected: _budgetLabel,
                        onSelected: (value) =>
                            setState(() => _budgetLabel = value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.tr('edit_profile_preferences'),
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _TwoColumnWrap(
                  children: [
                    _SelectionField(
                      label: locale.tr('edit_profile_routine_level'),
                      value: _friendlyText(_routinePreference, locale),
                      onTap: () => _showChoiceSheet(
                        context,
                        title: locale.tr('edit_profile_routine_level'),
                        options: _mergedOptions(
                          OnboardingState.routineOptions,
                          _routinePreference == null
                              ? const <String>[]
                              : [_routinePreference!],
                        ),
                        selected: _routinePreference,
                        onSelected: (value) =>
                            setState(() => _routinePreference = value),
                      ),
                    ),
                    _SelectionField(
                      label: locale.tr('profile_sensitivity'),
                      value: _hasSensitivity
                          ? '${_sensitivity.round()}/10'
                          : locale.tr('profile_not_provided'),
                      onTap: () => setState(() => _hasSensitivity = true),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        locale.tr('edit_profile_sensitivity_level'),
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    Text(
                      _hasSensitivity
                          ? '${_sensitivity.round()}/10'
                          : locale.tr('edit_profile_sensitivity_off'),
                      style: textTheme.labelLarge,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primaryDark,
                    inactiveTrackColor: AppColors.secondary,
                    thumbColor: AppColors.primaryDark,
                    overlayColor: AppColors.primary.withValues(alpha: 0.12),
                  ),
                  child: Slider(
                    value: _sensitivity.clamp(1, 10),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (value) => setState(() {
                      _hasSensitivity = true;
                      _sensitivity = value;
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.tr('edit_profile_concerns'),
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  locale.tr('edit_profile_concerns_subtitle'),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: concernOptions
                      .map(
                        (option) => _ChoiceChipCard(
                          label: option,
                          selected: _concerns.contains(option),
                          onTap: () => setState(() {
                            if (_concerns.contains(option)) {
                              _concerns.remove(option);
                            } else {
                              _concerns.add(option);
                            }
                          }),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.tr('edit_profile_goals'),
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  locale.tr('edit_profile_goals_subtitle'),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: goalOptions
                      .map(
                        (option) => _ChoiceChipCard(
                          label: option,
                          selected: _goals.contains(option),
                          onTap: () => setState(() {
                            if (_goals.contains(option)) {
                              _goals.remove(option);
                            } else {
                              _goals.add(option);
                            }
                          }),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.tr('edit_profile_save_changes'),
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  locale.tr('edit_profile_save_subtitle'),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: locale.tr('profile_save'),
                  icon: const Icon(Icons.check_rounded),
                  isLoading: appState.isBusy,
                  onPressed: () => _saveProfile(context, refreshRoutine: false),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: locale.tr('edit_profile_save_refresh_ai'),
                  variant: AppButtonVariant.secondary,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  isLoading: appState.isBusy,
                  onPressed: () => _saveProfile(context, refreshRoutine: true),
                ),
              ],
            ),
          ),
          if (profile == null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.onboarding),
              child: Text(locale.tr('edit_profile_complete_onboarding')),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 22, now.month, now.day),
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (selected != null) {
      setState(() => _dateOfBirth = selected);
    }
  }

  Future<void> _saveProfile(
    BuildContext context, {
    required bool refreshRoutine,
  }) async {
    final appState = context.read<AppState>();
    final existing = appState.profile;
    final goals = _goals.toList()..sort();
    final concerns = _concerns.toList()..sort();
    final payload = {
      'displayName': appState.profileDisplayName,
      'dateOfBirth': _dateOfBirth?.toIso8601String(),
      'gender': _enumGenderValue(_gender),
      'age': _dateOfBirth == null ? null : _ageFromDate(_dateOfBirth!),
      'birthYear': _dateOfBirth?.year,
      'skinType': _skinType?.toLowerCase(),
      'monthlyBudget': _budgetLabel == null
          ? existing?.monthlyBudget?.round()
          : OnboardingState.budgetOptions[_budgetLabel]?.round(),
      'budgetLabel': _budgetLabel,
      'concerns': concerns,
      'currentRoutineLevel': _routinePreference,
      'goals': goals,
      'skinGoals': goals,
      'healthIssues': existing?.healthIssues ?? const <String>[],
      'allergies': existing?.allergies ?? const <String>[],
      'avoidIngredients': existing?.avoidIngredients ?? const <String>[],
      'rednessWhenNewProducts': existing?.rednessWhenNewProducts,
      'rednessWhenSunOrExercise': existing?.rednessWhenSunOrExercise,
      'sensitivityLevel': _hasSensitivity ? _sensitivity.round() : null,
    };

    try {
      await appState.saveSkinProfile(payload, refreshRoutine: refreshRoutine);
      if (!context.mounted) {
        return;
      }
      final locale = AppLocale.of(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            refreshRoutine
                ? locale.tr('edit_profile_saved_refreshed')
                : locale.tr('profile_saved_success'),
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      final locale = AppLocale.of(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appState.errorMessage ?? locale.tr('edit_profile_error_save'),
          ),
        ),
      );
    }
  }
}

class _TwoColumnWrap extends StatelessWidget {
  const _TwoColumnWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSingleColumn = constraints.maxWidth < 360;
        if (useSingleColumn) {
          return Column(
            children: children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: child,
                  ),
                )
                .toList(),
          );
        }

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: children
              .map(
                (child) => SizedBox(
                  width: (constraints.maxWidth - AppSpacing.sm) / 2,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SelectionField extends StatelessWidget {
  const _SelectionField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: Colors.white),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.primaryDark),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primaryDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.secondary : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.white,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.primaryDark),
          ),
        ),
      ),
    );
  }
}

Future<void> _showChoiceSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  required String? selected,
  required ValueChanged<String> onSelected,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.md),
              ...options.map(
                (option) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(option),
                  trailing: selected == option
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primaryDark,
                        )
                      : null,
                  onTap: () {
                    onSelected(option);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

List<String> _mergedOptions(
  Iterable<String> defaults,
  Iterable<String> current,
) {
  final merged = <String>[];
  for (final item in [...current, ...defaults]) {
    final trimmed = item.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    if (!merged.any(
      (existing) => existing.toLowerCase() == trimmed.toLowerCase(),
    )) {
      merged.add(trimmed);
    }
  }
  return merged;
}

DateTime? _tryParseDate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

String _friendlyText(String? value, AppLocale locale) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? locale.tr('profile_not_provided') : trimmed;
}

String _genderLabel(OnboardingGender? gender, AppLocale locale) {
  switch (gender) {
    case OnboardingGender.male:
      return locale.tr('edit_profile_gender_male');
    case OnboardingGender.female:
      return locale.tr('edit_profile_gender_female');
    case OnboardingGender.other:
      return locale.tr('edit_profile_gender_other');
    case OnboardingGender.preferNotToSay:
      return locale.tr('edit_profile_gender_prefer_not_to_say');
    case null:
      return locale.tr('profile_not_provided');
  }
}

OnboardingGender? _parseGender(String? value) {
  switch (value?.trim().toLowerCase()) {
    case 'male':
      return OnboardingGender.male;
    case 'female':
      return OnboardingGender.female;
    case 'other':
      return OnboardingGender.other;
    case 'prefer not to say':
    case 'prefer_not_to_say':
    case 'prefernottosay':
      return OnboardingGender.preferNotToSay;
    default:
      return null;
  }
}

OnboardingGender? _genderFromLabel(String value, AppLocale locale) {
  final val = value.trim();
  if (val == locale.tr('edit_profile_gender_male')) {
    return OnboardingGender.male;
  }
  if (val == locale.tr('edit_profile_gender_female')) {
    return OnboardingGender.female;
  }
  if (val == locale.tr('edit_profile_gender_other')) {
    return OnboardingGender.other;
  }
  if (val == locale.tr('edit_profile_gender_prefer_not_to_say')) {
    return OnboardingGender.preferNotToSay;
  }
  return null;
}

String? _enumGenderValue(OnboardingGender? gender) {
  switch (gender) {
    case OnboardingGender.male:
      return 'male';
    case OnboardingGender.female:
      return 'female';
    case OnboardingGender.other:
      return 'other';
    case OnboardingGender.preferNotToSay:
      return 'preferNotToSay';
    case null:
      return null;
  }
}

int _ageFromDate(DateTime dateOfBirth) {
  final now = DateTime.now();
  var years = now.year - dateOfBirth.year;
  final hasHadBirthday =
      now.month > dateOfBirth.month ||
      (now.month == dateOfBirth.month && now.day >= dateOfBirth.day);
  if (!hasHadBirthday) {
    years--;
  }
  return years;
}
