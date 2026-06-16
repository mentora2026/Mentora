import 'package:flutter_test/flutter_test.dart';
import 'package:psych_support_app/data/models/interview.dart';

void main() {
  group('ChatMessage.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        "id": "msg-1",
        "sender": "bot",
        "message_text_ar": "كيف تشعر اليوم؟",
        "message_order": 1,
        "created_at": "2026-01-01T10:30:00Z",
      };

      final message = ChatMessage.fromJson(json);

      expect(message.id, "msg-1");
      expect(message.sender, "bot");
      expect(message.messageTextAr, "كيف تشعر اليوم؟");
      expect(message.messageOrder, 1);
      expect(message.createdAt, DateTime.parse("2026-01-01T10:30:00Z"));
      expect(message.isBot, isTrue);
    });

    test('isBot is false for patient messages', () {
      final message = ChatMessage.fromJson({
        "id": "msg-2",
        "sender": "patient",
        "message_text_ar": "أشعر بالتحسن",
        "message_order": 2,
        "created_at": "2026-01-01T10:31:00Z",
      });

      expect(message.isBot, isFalse);
    });
  });

  group('InterviewSession.fromJson', () {
    test('parses session without conversation', () {
      final json = {
        "id": "session-1",
        "status": "in_progress",
        "trigger_type": "manual",
        "started_at": "2026-01-01T10:00:00Z",
        "ended_at": null,
        "total_questions_asked": 0,
        "session_summary_ar": null,
      };

      final session = InterviewSession.fromJson(json);

      expect(session.id, "session-1");
      expect(session.isInProgress, isTrue);
      expect(session.endedAt, isNull);
      expect(session.conversation, isEmpty);
    });

    test('parses a completed session with conversation messages', () {
      final json = {
        "id": "session-2",
        "status": "completed",
        "trigger_type": "daily_checkin",
        "started_at": "2026-01-01T10:00:00Z",
        "ended_at": "2026-01-01T10:15:00Z",
        "total_questions_asked": 5,
        "session_summary_ar": "تم استكمال الجلسة بنجاح.",
        "conversation": [
          {
            "id": "m1",
            "sender": "bot",
            "message_text_ar": "مرحباً",
            "message_order": 1,
            "created_at": "2026-01-01T10:00:05Z",
          },
          {
            "id": "m2",
            "sender": "patient",
            "message_text_ar": "أهلاً",
            "message_order": 2,
            "created_at": "2026-01-01T10:00:10Z",
          },
        ],
      };

      final session = InterviewSession.fromJson(json);

      expect(session.isInProgress, isFalse);
      expect(session.endedAt, DateTime.parse("2026-01-01T10:15:00Z"));
      expect(session.conversation, hasLength(2));
      expect(session.conversation.first.sender, "bot");
      expect(session.conversation.last.sender, "patient");
      expect(session.sessionSummaryAr, "تم استكمال الجلسة بنجاح.");
    });
  });

  group('InterviewTurnResult.fromJson', () {
    test('parses a turn that continues the session', () {
      final json = {
        "session": {
          "id": "session-1",
          "status": "in_progress",
          "trigger_type": "manual",
          "started_at": "2026-01-01T10:00:00Z",
          "ended_at": null,
          "total_questions_asked": 1,
          "session_summary_ar": null,
        },
        "bot_message_ar": "سؤال آخر هنا",
        "is_session_ended": false,
        "risk_assessment_id": null,
      };

      final result = InterviewTurnResult.fromJson(json);

      expect(result.session.id, "session-1");
      expect(result.botMessageAr, "سؤال آخر هنا");
      expect(result.isSessionEnded, isFalse);
      expect(result.riskAssessmentId, isNull);
    });

    test('parses a turn that ends the session with a risk assessment id', () {
      final json = {
        "session": {
          "id": "session-1",
          "status": "completed",
          "trigger_type": "manual",
          "started_at": "2026-01-01T10:00:00Z",
          "ended_at": "2026-01-01T10:20:00Z",
          "total_questions_asked": 8,
          "session_summary_ar": "ملخص الجلسة",
        },
        "bot_message_ar": "شكراً لمشاركتك",
        "is_session_ended": true,
        "risk_assessment_id": "risk-123",
      };

      final result = InterviewTurnResult.fromJson(json);

      expect(result.isSessionEnded, isTrue);
      expect(result.riskAssessmentId, "risk-123");
      expect(result.session.isInProgress, isFalse);
    });
  });
}
