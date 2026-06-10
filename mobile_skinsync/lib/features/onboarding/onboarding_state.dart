import 'package:flutter/material.dart';

enum OnboardingGender { male, female, other, preferNotToSay }

String _enumValue(Object value) => value.toString().split('.').last;

class OnboardingState extends ChangeNotifier {
  OnboardingState({String initialDisplayName = ''})
    : displayName = initialDisplayName;

  static const totalSteps = 4;

  int currentStep = 0;
  String displayName;
  DateTime? dateOfBirth;
  OnboardingGender? gender;
  bool isSubmitting = false;

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
    0 => true,
    1 => displayName.trim().isNotEmpty,
    2 => dateOfBirth != null,
    3 => gender != null,
    _ => false,
  };

  String? get validationMessage => switch (currentStep) {
    1 => displayName.trim().isEmpty ? 'Please enter your display name.' : null,
    2 => dateOfBirth == null ? 'Please select your date of birth.' : null,
    3 => gender == null ? 'Please select your gender.' : null,
    _ => null,
  };

  int? get age {
    if (dateOfBirth == null) {
      return null;
    }
    final now = DateTime.now();
    var years = now.year - dateOfBirth!.year;
    final hasHadBirthdayThisYear =
        now.month > dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day >= dateOfBirth!.day);
    if (!hasHadBirthdayThisYear) {
      years--;
    }
    return years < 0 ? null : years;
  }

  int? get birthYear => dateOfBirth?.year;

  Map<String, dynamic> toPayload() {
    return {
      'displayName': displayName.trim(),
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': _enumValue(gender ?? OnboardingGender.preferNotToSay),
      'age': age,
      'birthYear': birthYear,
    };
  }
}
