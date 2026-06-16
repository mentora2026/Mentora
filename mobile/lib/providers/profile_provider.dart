import 'package:flutter/foundation.dart';

import '../data/models/user.dart';
import '../data/repositories/patient_repository.dart';

class ProfileProvider extends ChangeNotifier {
  final PatientRepository _repository = PatientRepository();

  PatientProfile? profile;
  List<ChronicCondition> allConditions = [];
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
      ]);
      profile = results[0] as PatientProfile;
      allConditions = results[1] as List<ChronicCondition>;
    } catch (e) {
      errorMessageAr = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    num? diseaseDurationMonths,
    String? medications,
    num? sleepHoursAvg,
    String? activityLevel,
    String? socialSupportLevel,
    String? medicalBackground,
  }) async {
    try {
      profile = await _repository.updateMyProfile(
        diseaseDurationMonths: diseaseDurationMonths,
        medications: medications,
        sleepHoursAvg: sleepHoursAvg,
        activityLevel: activityLevel,
        socialSupportLevel: socialSupportLevel,
        medicalBackground: medicalBackground,
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
