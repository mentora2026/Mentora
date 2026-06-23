import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/extras.dart';

class RecommendationRepository {
  final ApiClient _client = ApiClient.instance;

  Future<List<PatientRecommendation>> getMyRecommendations() async {
    final response = await _client.get(ApiConstants.myRecommendations);
    return (response as List<dynamic>).map((e) => PatientRecommendation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markViewed(String patientRecommendationId) async {
    await _client.post(ApiConstants.recommendationViewed(patientRecommendationId));
  }

  Future<void> submitFeedback(String patientRecommendationId, bool isHelpful) async {
    await _client.post(
      ApiConstants.recommendationFeedback(patientRecommendationId),
      body: {"is_helpful": isHelpful},
    );
  }

  Future<void> deleteRecommendation(String patientRecommendationId) async {
    await _client.delete(ApiConstants.deleteRecommendation(patientRecommendationId));
  }
}

class NotificationRepository {
  final ApiClient _client = ApiClient.instance;

  Future<List<AppNotification>> getNotifications() async {
    final response = await _client.get(ApiConstants.notifications);
    return (response as List<dynamic>).map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markRead(String notificationId) async {
    await _client.post(ApiConstants.notificationRead(notificationId));
  }

  Future<void> deleteNotification(String notificationId) async {
    await _client.delete(ApiConstants.deleteNotification(notificationId));
  }

  Future<void> clearAllNotifications() async {
    await _client.delete(ApiConstants.clearAllNotifications);
  }

  Future<void> registerDevice(String fcmToken, {String? deviceType}) async {
    await _client.post(
      ApiConstants.deviceRegister,
      body: {
        "fcm_token": fcmToken,
        if (deviceType != null) "device_type": deviceType,
      },
    );
  }
}
