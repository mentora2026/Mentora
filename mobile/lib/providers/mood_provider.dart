import 'package:flutter/foundation.dart';

import '../data/models/assessment.dart';
import '../data/repositories/assessment_repository.dart';

class MoodProvider extends ChangeNotifier {
  final AssessmentRepository _repository = AssessmentRepository();

  List<MoodEntry> entries = [];
  List<MoodTrendPoint> trend = [];
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessageAr;

  Future<void> load() async {
    isLoading = true;
    errorMessageAr = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.listMoodEntries(),
        _repository.getMoodTrend(),
      ]);
      entries = results[0] as List<MoodEntry>;
      trend = results[1] as List<MoodTrendPoint>;
    } catch (e) {
      errorMessageAr = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addEntry({required int moodValue, String? noteAr}) async {
    isSaving = true;
    errorMessageAr = null;
    notifyListeners();

    try {
      final entry = await _repository.createMoodEntry(moodValue: moodValue, noteAr: noteAr);
      entries.insert(0, entry);
      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessageAr = e.toString();
      isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
