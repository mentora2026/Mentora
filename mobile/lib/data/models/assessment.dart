class MoodEntry {
  final String id;
  final int moodValue;
  final String? noteAr;
  final String source;
  final DateTime recordedAt;

  MoodEntry({
    required this.id,
    required this.moodValue,
    this.noteAr,
    required this.source,
    required this.recordedAt,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json["id"] as String,
      moodValue: json["mood_value"] as int,
      noteAr: json["note_ar"] as String?,
      source: json["source"] as String,
      recordedAt: DateTime.parse(json["recorded_at"] as String),
    );
  }
}

class MoodTrendPoint {
  final DateTime date;
  final double averageMood;

  MoodTrendPoint({required this.date, required this.averageMood});

  factory MoodTrendPoint.fromJson(Map<String, dynamic> json) {
    return MoodTrendPoint(
      date: DateTime.parse(json["date"] as String),
      averageMood: (json["average_mood"] as num).toDouble(),
    );
  }
}

class RiskAssessment {
  final String id;
  final String interviewSessionId;
  final int riskLevel;
  final num anxietyScore;
  final num stressScore;
  final num sadnessScore;
  final num burnoutScore;
  final num sleepQualityScore;
  final num adherenceScore;
  final num compositeScore;
  final String explanationAr;
  final Map<String, dynamic> explanationFactors;
  final DateTime createdAt;

  RiskAssessment({
    required this.id,
    required this.interviewSessionId,
    required this.riskLevel,
    required this.anxietyScore,
    required this.stressScore,
    required this.sadnessScore,
    required this.burnoutScore,
    required this.sleepQualityScore,
    required this.adherenceScore,
    required this.compositeScore,
    required this.explanationAr,
    required this.explanationFactors,
    required this.createdAt,
  });

  factory RiskAssessment.fromJson(Map<String, dynamic> json) {
    return RiskAssessment(
      id: json["id"] as String,
      interviewSessionId: json["interview_session_id"] as String,
      riskLevel: json["risk_level"] as int,
      anxietyScore: json["anxiety_score"] as num,
      stressScore: json["stress_score"] as num,
      sadnessScore: json["sadness_score"] as num,
      burnoutScore: json["burnout_score"] as num,
      sleepQualityScore: json["sleep_quality_score"] as num,
      adherenceScore: json["adherence_score"] as num,
      compositeScore: json["composite_score"] as num,
      explanationAr: json["explanation_ar"] as String,
      explanationFactors: json["explanation_factors_json"] as Map<String, dynamic>,
      createdAt: DateTime.parse(json["created_at"] as String),
    );
  }
}

class RiskProgressionPoint {
  final DateTime date;
  final int riskLevel;
  final num compositeScore;

  RiskProgressionPoint({required this.date, required this.riskLevel, required this.compositeScore});

  factory RiskProgressionPoint.fromJson(Map<String, dynamic> json) {
    return RiskProgressionPoint(
      date: DateTime.parse(json["date"] as String),
      riskLevel: json["risk_level"] as int,
      compositeScore: json["composite_score"] as num,
    );
  }
}

class ReportData {
  final String id;
  final String reportType;
  final String periodStart;
  final String periodEnd;
  final String summaryAr;
  final Map<String, dynamic> metrics;
  final DateTime generatedAt;

  ReportData({
    required this.id,
    required this.reportType,
    required this.periodStart,
    required this.periodEnd,
    required this.summaryAr,
    required this.metrics,
    required this.generatedAt,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      id: json["id"] as String,
      reportType: json["report_type"] as String,
      periodStart: json["period_start"] as String,
      periodEnd: json["period_end"] as String,
      summaryAr: json["summary_ar"] as String,
      metrics: json["metrics_json"] as Map<String, dynamic>,
      generatedAt: DateTime.parse(json["generated_at"] as String),
    );
  }
}
