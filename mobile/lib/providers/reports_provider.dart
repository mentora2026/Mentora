import 'package:flutter/foundation.dart';

import '../data/models/assessment.dart';
import '../data/repositories/assessment_repository.dart';

class ReportsProvider extends ChangeNotifier {
  final AssessmentRepository _repository = AssessmentRepository();

  ReportData? weeklyReport;
  List<MoodTrendPoint> moodTrend = [];
  List<RiskProgressionPoint> riskProgression = [];
  bool isLoading = false;
  String? errorMessageAr;

  Future<void> load() async {
    isLoading = true;
    errorMessageAr = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getWeeklyReport(),
        _repository.getMoodTrend(days: 30),
        _repository.getRiskProgression(),
      ]);
      weeklyReport = results[0] as ReportData;
      moodTrend = results[1] as List<MoodTrendPoint>;
      riskProgression = results[2] as List<RiskProgressionPoint>;
    } catch (e) {
      errorMessageAr = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
