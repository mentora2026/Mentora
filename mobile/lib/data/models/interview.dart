class ChatMessage {
  final String id;
  final String sender; // "bot" | "patient"
  final String messageTextAr;
  final int messageOrder;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.messageTextAr,
    required this.messageOrder,
    required this.createdAt,
  });

  bool get isBot => sender == "bot";

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json["id"] as String,
      sender: json["sender"] as String,
      messageTextAr: json["message_text_ar"] as String,
      messageOrder: json["message_order"] as int,
      createdAt: DateTime.parse(json["created_at"] as String),
    );
  }
}

class InterviewSession {
  final String id;
  final String status; // in_progress | completed | abandoned
  final String triggerType;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int totalQuestionsAsked;
  final String? sessionSummaryAr;
  final List<ChatMessage> conversation;

  InterviewSession({
    required this.id,
    required this.status,
    required this.triggerType,
    required this.startedAt,
    this.endedAt,
    required this.totalQuestionsAsked,
    this.sessionSummaryAr,
    this.conversation = const [],
  });

  bool get isInProgress => status == "in_progress";

  factory InterviewSession.fromJson(Map<String, dynamic> json) {
    return InterviewSession(
      id: json["id"] as String,
      status: json["status"] as String,
      triggerType: json["trigger_type"] as String,
      startedAt: DateTime.parse(json["started_at"] as String),
      endedAt: json["ended_at"] != null ? DateTime.parse(json["ended_at"] as String) : null,
      totalQuestionsAsked: json["total_questions_asked"] as int,
      sessionSummaryAr: json["session_summary_ar"] as String?,
      conversation: (json["conversation"] as List<dynamic>? ?? [])
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Response returned after starting a session or submitting an answer.
class InterviewTurnResult {
  final InterviewSession session;
  final String? botMessageAr;
  final bool isSessionEnded;
  final String? riskAssessmentId;

  InterviewTurnResult({
    required this.session,
    this.botMessageAr,
    required this.isSessionEnded,
    this.riskAssessmentId,
  });

  factory InterviewTurnResult.fromJson(Map<String, dynamic> json) {
    return InterviewTurnResult(
      session: InterviewSession.fromJson(json["session"] as Map<String, dynamic>),
      botMessageAr: json["bot_message_ar"] as String?,
      isSessionEnded: json["is_session_ended"] as bool,
      riskAssessmentId: json["risk_assessment_id"] as String?,
    );
  }
}
