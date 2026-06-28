/// Central place for backend API configuration.
///
/// Deployed backend API.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = "https://mentora-rv7y.onrender.com/api/v1";

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
  static const String medications = "$baseUrl/medications";

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
  static String deleteRecommendation(String id) => "$baseUrl/recommendations/$id";

  // Notifications
  static const String notifications = "$baseUrl/notifications";
  static String notificationRead(String id) => "$baseUrl/notifications/$id/read";
  static String deleteNotification(String id) => "$baseUrl/notifications/$id";
  static const String clearAllNotifications = "$baseUrl/notifications/all";
  static const String deviceRegister = "$baseUrl/devices/register";

  // Reports
  static const String dailyReport = "$baseUrl/reports/daily";
  static const String weeklyReport = "$baseUrl/reports/weekly";
  static const String monthlyReport = "$baseUrl/reports/monthly";
  static const String riskProgression = "$baseUrl/reports/risk-progression";

  // Content Library
  static const String contentLibrary = "$baseUrl/content-library";
}
