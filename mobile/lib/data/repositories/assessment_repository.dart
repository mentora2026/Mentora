import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/assessment.dart';

class AssessmentRepository {
  final ApiClient _client = ApiClient.instance;

  // ----- Mood -----
  Future<MoodEntry> createMoodEntry({required int moodValue, String? noteAr}) async {
    final response = await _client.post(
      ApiConstants.moodEntries,
      body: {"mood_value": moodValue, if (noteAr != null && noteAr.isNotEmpty) "note_ar": noteAr},
    );
    return MoodEntry.fromJson(response as Map<String, dynamic>);
  }

  Future<List<MoodEntry>> listMoodEntries() async {
    final response = await _client.get(ApiConstants.moodEntries);
    return (response as List<dynamic>).map((e) => MoodEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MoodTrendPoint>> getMoodTrend({int days = 30}) async {
    final response = await _client.get("${ApiConstants.moodTrend}?days=$days");
    return (response as List<dynamic>).map((e) => MoodTrendPoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ----- Risk -----
  Future<RiskAssessment?> getLatestRiskAssessment() async {
    try {
      final response = await _client.get(ApiConstants.latestRiskAssessment);
      return RiskAssessment.fromJson(response as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<RiskAssessment>> listRiskAssessments() async {
    final response = await _client.get(ApiConstants.riskAssessments);
    return (response as List<dynamic>).map((e) => RiskAssessment.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ----- Reports -----
  Future<ReportData> getDailyReport() async {
    final response = await _client.get(ApiConstants.dailyReport);
    return ReportData.fromJson(response as Map<String, dynamic>);
  }

  Future<ReportData> getWeeklyReport() async {
    final response = await _client.get(ApiConstants.weeklyReport);
    return ReportData.fromJson(response as Map<String, dynamic>);
  }

  Future<ReportData> getMonthlyReport() async {
    final response = await _client.get(ApiConstants.monthlyReport);
    return ReportData.fromJson(response as Map<String, dynamic>);
  }

  Future<List<RiskProgressionPoint>> getRiskProgression() async {
    final response = await _client.get(ApiConstants.riskProgression);
    return (response as List<dynamic>).map((e) => RiskProgressionPoint.fromJson(e as Map<String, dynamic>)).toList();
  }
}
