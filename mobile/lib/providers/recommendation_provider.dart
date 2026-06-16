import 'package:flutter/foundation.dart';

import '../data/models/extras.dart';
import '../data/repositories/extras_repository.dart';

class RecommendationProvider extends ChangeNotifier {
  final RecommendationRepository _repository = RecommendationRepository();

  List<PatientRecommendation> recommendations = [];
  bool isLoading = false;
  String? errorMessageAr;

  Future<void> load() async {
    isLoading = true;
    errorMessageAr = null;
    notifyListeners();

    try {
      recommendations = await _repository.getMyRecommendations();
    } catch (e) {
      errorMessageAr = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markViewed(PatientRecommendation rec) async {
    if (rec.isViewed) return;
    try {
      await _repository.markViewed(rec.id);
      final index = recommendations.indexWhere((r) => r.id == rec.id);
      if (index != -1) {
        recommendations[index] = PatientRecommendation(
          id: rec.id,
          recommendation: rec.recommendation,
          deliveredAt: rec.deliveredAt,
          isViewed: true,
          isHelpfulFeedback: rec.isHelpfulFeedback,
        );
        notifyListeners();
      }
    } catch (_) {
      // Non-critical - ignore failures silently.
    }
  }

  Future<void> submitFeedback(PatientRecommendation rec, bool isHelpful) async {
    try {
      await _repository.submitFeedback(rec.id, isHelpful);
      final index = recommendations.indexWhere((r) => r.id == rec.id);
      if (index != -1) {
        recommendations[index] = PatientRecommendation(
          id: rec.id,
          recommendation: rec.recommendation,
          deliveredAt: rec.deliveredAt,
          isViewed: rec.isViewed,
          isHelpfulFeedback: isHelpful,
        );
        notifyListeners();
      }
    } catch (e) {
      errorMessageAr = e.toString();
      notifyListeners();
    }
  }
}
