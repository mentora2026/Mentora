/// Central place for backend API configuration.
///
/// During development with an Android emulator, `10.0.2.2` maps to the host
/// machine's `localhost`. For a physical device, replace this with your
/// machine's LAN IP (e.g. `http://192.168.1.50:8000`) or your deployed
/// backend URL (e.g. `https://api.yourapp.com`).
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = "http://10.0.2.2:8000/api/v1";

  // Auth
  static const String register = "$baseUrl/auth/register";
  static const String login = "$baseUrl/auth/login";
  static const String refresh = "$baseUrl/auth/refresh";
  static const String changePassword = "$baseUrl/auth/change-password";
  static const String logout = "$baseUrl/auth/logout";
  static const String me = "$baseUrl/auth/me";

  // Patient profile
  static const String myProfile = "$baseUrl/patients/me";
  static const String myConditions = "$baseUrl/patients/me/conditions";
  static const String chronicConditions = "$baseUrl/conditions";

  // Adaptive interview
  static const String interviewStart = "$baseUrl/interviews/start";
  static String interviewAnswer(String sessionId) => "$baseUrl/interviews/$sessionId/answer";
  static String interviewEnd(String sessionId) => "$baseUrl/interviews/$sessionId/end";
  static String interviewDetail(String sessionId) => "$baseUrl/interviews/$sessionId";
  static const String interviewHistory = "$baseUrl/interviews/history";

  // Mood
  static const String moodEntries = "$baseUrl/mood-entries";
  static const String moodTrend = "$baseUrl/mood-entries/trend";

  // Risk
  static const String latestRiskAssessment = "$baseUrl/risk-assessments/latest";
  static const String riskAssessments = "$baseUrl/risk-assessments";

  // Recommendations
  static const String myRecommendations = "$baseUrl/recommendations/me";
  static String recommendationViewed(String id) => "$baseUrl/recommendations/$id/viewed";
  static String recommendationFeedback(String id) => "$baseUrl/recommendations/$id/feedback";

  // Notifications
  static const String notifications = "$baseUrl/notifications";
  static String notificationRead(String id) => "$baseUrl/notifications/$id/read";
  static const String deviceRegister = "$baseUrl/devices/register";

  // Reports
  static const String dailyReport = "$baseUrl/reports/daily";
  static const String weeklyReport = "$baseUrl/reports/weekly";
  static const String monthlyReport = "$baseUrl/reports/monthly";
  static const String riskProgression = "$baseUrl/reports/risk-progression";
}
