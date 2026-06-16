import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/interview.dart';

class InterviewRepository {
  final ApiClient _client = ApiClient.instance;

  Future<InterviewTurnResult> startInterview({String triggerType = "manual"}) async {
    final response = await _client.post(
      ApiConstants.interviewStart,
      body: {"trigger_type": triggerType},
    );
    return InterviewTurnResult.fromJson(response as Map<String, dynamic>);
  }

  Future<InterviewTurnResult> submitAnswer({
    required String sessionId,
    String? answerTextAr,
    num? answerValueNumeric,
  }) async {
    final body = <String, dynamic>{};
    if (answerTextAr != null) body["answer_text_ar"] = answerTextAr;
    if (answerValueNumeric != null) body["answer_value_numeric"] = answerValueNumeric;

    final response = await _client.post(ApiConstants.interviewAnswer(sessionId), body: body);
    return InterviewTurnResult.fromJson(response as Map<String, dynamic>);
  }

  Future<InterviewTurnResult> endSessionEarly(String sessionId) async {
    final response = await _client.post(ApiConstants.interviewEnd(sessionId));
    return InterviewTurnResult.fromJson(response as Map<String, dynamic>);
  }

  Future<InterviewSession> getSession(String sessionId) async {
    final response = await _client.get(ApiConstants.interviewDetail(sessionId));
    return InterviewSession.fromJson(response as Map<String, dynamic>);
  }

  Future<List<InterviewSession>> getHistory() async {
    final response = await _client.get(ApiConstants.interviewHistory);
    return (response as List<dynamic>).map((e) => InterviewSession.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Returns the currently open session (if any), or null if none exists.
  Future<InterviewSession?> getActiveSession() async {
    final sessions = await getHistory();
    for (final session in sessions) {
      if (session.isInProgress) return session;
    }
    return null;
  }
}
