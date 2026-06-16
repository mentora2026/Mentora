import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/user.dart';

class PatientRepository {
  final ApiClient _client = ApiClient.instance;

  Future<PatientProfile> getMyProfile() async {
    final response = await _client.get(ApiConstants.myProfile);
    return PatientProfile.fromJson(response as Map<String, dynamic>);
  }

  Future<PatientProfile> updateMyProfile({
    String? dateOfBirth,
    String? gender,
    num? diseaseDurationMonths,
    String? medications,
    num? sleepHoursAvg,
    String? activityLevel,
    String? socialSupportLevel,
    String? medicalBackground,
  }) async {
    final body = <String, dynamic>{};
    if (dateOfBirth != null) body["date_of_birth"] = dateOfBirth;
    if (gender != null) body["gender"] = gender;
    if (diseaseDurationMonths != null) body["disease_duration_months"] = diseaseDurationMonths;
    if (medications != null) body["medications"] = medications;
    if (sleepHoursAvg != null) body["sleep_hours_avg"] = sleepHoursAvg;
    if (activityLevel != null) body["activity_level"] = activityLevel;
    if (socialSupportLevel != null) body["social_support_level"] = socialSupportLevel;
    if (medicalBackground != null) body["medical_background"] = medicalBackground;

    final response = await _client.put(ApiConstants.myProfile, body: body);
    return PatientProfile.fromJson(response as Map<String, dynamic>);
  }

  Future<List<ChronicCondition>> listChronicConditions() async {
    final response = await _client.get(ApiConstants.chronicConditions);
    return (response as List<dynamic>).map((e) => ChronicCondition.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PatientCondition>> listMyConditions() async {
    final response = await _client.get(ApiConstants.myConditions);
    return (response as List<dynamic>).map((e) => PatientCondition.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addMyCondition({required String chronicConditionId, bool isPrimary = false}) async {
    await _client.post(
      ApiConstants.myConditions,
      body: {"chronic_condition_id": chronicConditionId, "is_primary": isPrimary},
    );
  }

  Future<void> removeMyCondition(String chronicConditionId) async {
    await _client.delete("${ApiConstants.myConditions}/$chronicConditionId");
  }
}
