class Recommendation {
  final String id;
  final String category;
  final String titleAr;
  final String contentAr;
  final String? mediaUrl;

  Recommendation({
    required this.id,
    required this.category,
    required this.titleAr,
    required this.contentAr,
    this.mediaUrl,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json["id"] as String,
      category: json["category"] as String,
      titleAr: json["title_ar"] as String,
      contentAr: json["content_ar"] as String,
      mediaUrl: json["media_url"] as String?,
    );
  }
}

class PatientRecommendation {
  final String id;
  final Recommendation recommendation;
  final DateTime deliveredAt;
  final bool isViewed;
  final bool? isHelpfulFeedback;

  PatientRecommendation({
    required this.id,
    required this.recommendation,
    required this.deliveredAt,
    required this.isViewed,
    this.isHelpfulFeedback,
  });

  factory PatientRecommendation.fromJson(Map<String, dynamic> json) {
    return PatientRecommendation(
      id: json["id"] as String,
      recommendation: Recommendation.fromJson(json["recommendation"] as Map<String, dynamic>),
      deliveredAt: DateTime.parse(json["delivered_at"] as String),
      isViewed: json["is_viewed"] as bool,
      isHelpfulFeedback: json["is_helpful_feedback"] as bool?,
    );
  }
}

class AppNotification {
  final String id;
  final String type;
  final String titleAr;
  final String bodyAr;
  final bool isRead;
  final String status;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.titleAr,
    required this.bodyAr,
    required this.isRead,
    required this.status,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json["id"] as String,
      type: json["type"] as String,
      titleAr: json["title_ar"] as String,
      bodyAr: json["body_ar"] as String,
      isRead: json["is_read"] as bool,
      status: json["status"] as String,
      createdAt: DateTime.parse(json["created_at"] as String),
    );
  }
}

class ContentLibraryItem {
  final String id;
  final String contentType;
  final String key;
  final String? titleAr;
  final String bodyAr;
  final bool isPublished;

  ContentLibraryItem({
    required this.id,
    required this.contentType,
    required this.key,
    this.titleAr,
    required this.bodyAr,
    required this.isPublished,
  });

  factory ContentLibraryItem.fromJson(Map<String, dynamic> json) {
    return ContentLibraryItem(
      id: json["id"] as String,
      contentType: json["content_type"] as String,
      key: json["key"] as String,
      titleAr: json["title_ar"] as String?,
      bodyAr: json["body_ar"] as String,
      isPublished: json["is_published"] as bool,
    );
  }
}
