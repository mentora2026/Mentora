import 'package:flutter/foundation.dart';

import '../data/models/user.dart';
import '../data/repositories/patient_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final PatientRepository _repository = PatientRepository();

  PatientProfile? profile;
  List<ChronicCondition> allConditions = [];
  List<Medication> allMedications = [];
  bool isLoading = false;
  String? errorMessageAr;

  Future<void> load() async {
    isLoading = true;
    errorMessageAr = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getMyProfile(),
        _repository.listChronicConditions(),
        _repository.listMedications(),
      ]);
      profile = results[0] as PatientProfile;
      allConditions = results[1] as List<ChronicCondition>;
      allMedications = results[2] as List<Medication>;
    } catch (e) {
      errorMessageAr = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? dateOfBirth,
    String? gender,
    num? diseaseDurationMonths,
    List<String>? medications,
    num? sleepHoursAvg,
    String? activityLevel,
    String? socialSupportLevel,
    String? medicalBackground,
    num? heightCm,
    num? weightKg,
  }) async {
    try {
      profile = await _repository.updateMyProfile(
        dateOfBirth: dateOfBirth,
        gender: gender,
        diseaseDurationMonths: diseaseDurationMonths,
        medications: medications,
        sleepHoursAvg: sleepHoursAvg,
        activityLevel: activityLevel,
        socialSupportLevel: socialSupportLevel,
        medicalBackground: medicalBackground,
        heightCm: heightCm,
        weightKg: weightKg,
      );
      notifyListeners();
      return true;
    } catch (e) {
      errorMessageAr = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addCondition(String chronicConditionId, {bool isPrimary = false}) async {
    try {
      await _repository.addMyCondition(chronicConditionId: chronicConditionId, isPrimary: isPrimary);
      await load();
      return true;
    } catch (e) {
      errorMessageAr = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeCondition(String chronicConditionId) async {
    try {
      await _repository.removeMyCondition(chronicConditionId);
      await load();
      return true;
    } catch (e) {
      errorMessageAr = e.toString();
      notifyListeners();
      return false;
    }
  }
}
