import 'package:flutter/foundation.dart';

import '../data/models/assessment.dart';
import '../data/repositories/assessment_repository.dart';

class HomeProvider extends ChangeNotifier {
  final AssessmentRepository _repository = AssessmentRepository();

  RiskAssessment? latestRisk;
  bool isLoading = false;
  String? errorMessageAr;

  Future<void> load() async {
    isLoading = true;
    errorMessageAr = null;
    notifyListeners();

    try {
      latestRisk = await _repository.getLatestRiskAssessment();
    } catch (e) {
      errorMessageAr = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
