import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/models/app_models.dart';

enum OnboardingGender { male, female, other, preferNotToSay }

String _enumValue(Object value) => value.toString().split('.').last;

class OnboardingState extends ChangeNotifier {
  OnboardingState({
    required String initialDisplayName,
    SkinProfile? initialProfile,
  }) : displayName = initialDisplayName.trim().isEmpty
           ? initialProfile?.displayName?.trim() ?? ''
           : initialDisplayName.trim(),
       dateOfBirth = _tryParseDate(initialProfile?.dateOfBirth),
       gender = _parseGender(initialProfile?.gender),
       skinType = initialProfile?.skinType,
       concerns = List<String>.from(initialProfile?.concerns ?? const []),
       routineLevel = initialProfile?.currentRoutineLevel,
       budgetLabel = initialProfile?.budgetLabel,
       goals = List<String>.from(
         initialProfile?.goals.isNotEmpty == true
             ? initialProfile!.goals
             : initialProfile?.skinGoals ?? const [],
       );

  static const totalSteps = 5;

  static const skinTypeOptions = [
    'Dry',
    'Oily',
    'Combination',
    'Sensitive',
    'Normal',
  ];

  static const concernOptions = [
    'Acne',
    'Dark spots',
    'Redness',
    'Dehydration',
    'Large pores',
    'Uneven tone',
    'Dullness',
    'Sensitivity',
  ];

  static const routineOptions = [
    'Beginner',
    'Balanced',
    'Advanced',
    'Minimal',
  ];

  static const budgetOptions = {
    'Budget-friendly': 300000,
    'Balanced': 700000,
    'Premium': 1200000,
  };

  static const goalOptions = [
    'Clear breakouts',
    'Hydrate and calm',
    'Fade dark spots',
    'Strengthen barrier',
    'Glow and smooth texture',
    'Simplify my routine',
  ];

  int currentStep = 0;
  String displayName;
  DateTime? dateOfBirth;
  OnboardingGender? gender;
  String? skinType;
  List<String> concerns;
  String? routineLevel;
  String? budgetLabel;
  List<String> goals;
  File? skinPhoto;
  bool isSubmitting = false;

  double? get monthlyBudget {
    final label = budgetLabel;
    if (label == null) {
      return null;
    }
    return budgetOptions[label]?.toDouble();
  }

  void setDisplayName(String value) {
    displayName = value;
    notifyListeners();
  }

  void setDateOfBirth(DateTime value) {
    dateOfBirth = value;
    notifyListeners();
  }

  void setGender(OnboardingGender value) {
    gender = value;
    notifyListeners();
  }

  void setSkinType(String value) {
    skinType = value;
    notifyListeners();
  }

  void toggleConcern(String value) {
    if (concerns.contains(value)) {
      concerns.remove(value);
    } else {
      concerns.add(value);
    }
    notifyListeners();
  }

  void setRoutineLevel(String value) {
    routineLevel = value;
    notifyListeners();
  }

  void setBudgetLabel(String value) {
    budgetLabel = value;
    notifyListeners();
  }

  void toggleGoal(String value) {
    if (goals.contains(value)) {
      goals.remove(value);
    } else {
      goals.add(value);
    }
    notifyListeners();
  }

  void setPhoto(File? file) {
    skinPhoto = file;
    notifyListeners();
  }

  void setSubmitting(bool value) {
    isSubmitting = value;
    notifyListeners();
  }

  void back() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  void next() {
    if (!canContinue) {
      return;
    }
    if (currentStep < totalSteps - 1) {
      currentStep++;
      notifyListeners();
    }
  }

  bool get canContinue => switch (currentStep) {
    0 => displayName.trim().isNotEmpty && dateOfBirth != null && gender != null,
    1 => skinType != null && skinType!.trim().isNotEmpty,
    2 => routineLevel != null && routineLevel!.trim().isNotEmpty,
    3 => budgetLabel != null && goals.isNotEmpty,
    4 => true,
    _ => false,
  };

  String? get validationMessage => switch (currentStep) {
    0 => displayName.trim().isEmpty
        ? 'Please enter your display name.'
        : dateOfBirth == null
        ? 'Please select your date of birth.'
        : gender == null
        ? 'Please choose your gender.'
        : null,
    1 => skinType == null ? 'Please choose your skin type.' : null,
    2 => routineLevel == null ? 'Please tell SkinSync your current routine level.' : null,
    3 => budgetLabel == null
        ? 'Please choose your skincare budget.'
        : goals.isEmpty
        ? 'Please select at least one skincare goal.'
        : null,
    _ => null,
  };

  int? get age {
    final value = dateOfBirth;
    if (value == null) {
      return null;
    }
    final now = DateTime.now();
    var years = now.year - value.year;
    final hasHadBirthdayThisYear =
        now.month > value.month ||
        (now.month == value.month && now.day >= value.day);
    if (!hasHadBirthdayThisYear) {
      years--;
    }
    return years < 0 ? null : years;
  }

  int? get birthYear => dateOfBirth?.year;

  Map<String, dynamic> toPayload() {
    final selectedBudget = monthlyBudget;
    return {
      'displayName': displayName.trim(),
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': _enumValue(gender ?? OnboardingGender.preferNotToSay),
      'age': age,
      'birthYear': birthYear,
      'skinType': skinType?.toLowerCase(),
      'monthlyBudget': selectedBudget?.round(),
      'budgetLabel': budgetLabel,
      'concerns': concerns,
      'currentRoutineLevel': routineLevel,
      'goals': goals,
      'skinGoals': goals,
      'healthIssues': const <String>[],
      'allergies': const <String>[],
      'avoidIngredients': const <String>[],
    };
  }

  static DateTime? _tryParseDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  static OnboardingGender? _parseGender(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'male':
        return OnboardingGender.male;
      case 'female':
        return OnboardingGender.female;
      case 'other':
        return OnboardingGender.other;
      case 'prefernottosay':
      case 'prefer_not_to_say':
        return OnboardingGender.preferNotToSay;
      default:
        return null;
    }
  }
}
