import 'json_parsing.dart';

class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String role;
  final bool isActive;
  final String preferredLanguage;

  AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    required this.isActive,
    required this.preferredLanguage,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json["id"] as String,
      email: json["email"] as String,
      fullName: json["full_name"] as String,
      phoneNumber: json["phone_number"] as String?,
      role: json["role"] as String,
      isActive: json["is_active"] as bool,
      preferredLanguage: json["preferred_language"] as String? ?? "ar",
    );
  }
}

class ChronicCondition {
  final String id;
  final String code;
  final String nameEn;
  final String nameAr;
  final String? descriptionAr;

  ChronicCondition({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameAr,
    this.descriptionAr,
  });

  factory ChronicCondition.fromJson(Map<String, dynamic> json) {
    return ChronicCondition(
      id: json["id"] as String,
      code: json["code"] as String,
      nameEn: json["name_en"] as String,
      nameAr: json["name_ar"] as String,
      descriptionAr: json["description_ar"] as String?,
    );
  }
}

class Medication {
  final String id;
  final String nameEn;
  final String nameAr;
  final String? genericName;

  Medication({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.genericName,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json["id"] as String,
      nameEn: json["name_en"] as String,
      nameAr: json["name_ar"] as String,
      genericName: json["generic_name"] as String?,
    );
  }
}

class PatientCondition {
  final String id;
  final ChronicCondition chronicCondition;
  final String? diagnosedAt;
  final bool isPrimary;

  PatientCondition({
    required this.id,
    required this.chronicCondition,
    this.diagnosedAt,
    required this.isPrimary,
  });

  factory PatientCondition.fromJson(Map<String, dynamic> json) {
    return PatientCondition(
      id: json["id"] as String,
      chronicCondition: ChronicCondition.fromJson(
          json["chronic_condition"] as Map<String, dynamic>),
      diagnosedAt: json["diagnosed_at"] as String?,
      isPrimary: json["is_primary"] as bool,
    );
  }
}

class PatientProfile {
  final String id;
  final String? dateOfBirth;
  final String? gender;
  final num? diseaseDurationMonths;
  final List<String> medications;
  final num? sleepHoursAvg;
  final String? activityLevel;
  final String? socialSupportLevel;
  final String? medicalBackground;
  final num? heightCm;
  final num? weightKg;
  final bool onboardingCompleted;
  final List<PatientCondition> conditions;

  PatientProfile({
    required this.id,
    this.dateOfBirth,
    this.gender,
    this.diseaseDurationMonths,
    required this.medications,
    this.sleepHoursAvg,
    this.activityLevel,
    this.socialSupportLevel,
    this.medicalBackground,
    this.heightCm,
    this.weightKg,
    required this.onboardingCompleted,
    required this.conditions,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json["id"] as String,
      dateOfBirth: json["date_of_birth"] as String?,
      gender: json["gender"] as String?,
      diseaseDurationMonths: jsonNumOrNull(json["disease_duration_months"]),
      medications: (json["medications"] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      sleepHoursAvg: jsonNumOrNull(json["sleep_hours_avg"]),
      activityLevel: json["activity_level"] as String?,
      socialSupportLevel: json["social_support_level"] as String?,
      medicalBackground: json["medical_background"] as String?,
      heightCm: jsonNumOrNull(json["height_cm"]),
      weightKg: jsonNumOrNull(json["weight_kg"]),
      onboardingCompleted: json["onboarding_completed"] as bool? ?? false,
      conditions: (json["conditions"] as List<dynamic>? ?? [])
          .map((e) => PatientCondition.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
