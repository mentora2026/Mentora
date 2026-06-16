import 'package:flutter/foundation.dart';

import '../data/models/interview.dart';
import '../data/repositories/interview_repository.dart';

class InterviewProvider extends ChangeNotifier {
  final InterviewRepository _repository = InterviewRepository();

  InterviewSession? currentSession;
  final List<ChatMessage> messages = [];
  bool isLoading = false;
  bool isSending = false;
  String? errorMessageAr;
  String? lastRiskAssessmentId;

  /// Whether the *current question* expects a 1-5 scale answer.
  /// The backend doesn't currently echo the question type back in the turn
  /// response, so the chat UI defaults to free-text input with an optional
  /// scale picker the patient can open manually (see ChatInputBar).
  bool sessionEnded = false;

  Future<void> initialize() async {
    isLoading = true;
    errorMessageAr = null;
    notifyListeners();

    try {
      final active = await _repository.getActiveSession();
      if (active != null) {
        final detail = await _repository.getSession(active.id);
        currentSession = detail;
        messages
          ..clear()
          ..addAll(detail.conversation);
        sessionEnded = !detail.isInProgress;
      }
    } catch (e) {
      errorMessageAr = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startNewSession() async {
    isLoading = true;
    errorMessageAr = null;
    messages.clear();
    sessionEnded = false;
    lastRiskAssessmentId = null;
    notifyListeners();

    try {
      final result = await _repository.startInterview();
      _applyTurnResult(result);
    } catch (e) {
      errorMessageAr = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendAnswer({String? textAr, num? valueNumeric}) async {
    if (currentSession == null) return;

    // Optimistically show the patient's message.
    messages.add(
      ChatMessage(
        id: "local-${DateTime.now().microsecondsSinceEpoch}",
        sender: "patient",
        messageTextAr: textAr ?? valueNumeric?.toString() ?? "",
        messageOrder: messages.length + 1,
        createdAt: DateTime.now(),
      ),
    );
    isSending = true;
    errorMessageAr = null;
    notifyListeners();

    try {
      final result = await _repository.submitAnswer(
        sessionId: currentSession!.id,
        answerTextAr: textAr,
        answerValueNumeric: valueNumeric,
      );
      _applyTurnResult(result);
    } catch (e) {
      errorMessageAr = e.toString();
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> endSessionEarly() async {
    if (currentSession == null) return;

    isSending = true;
    notifyListeners();

    try {
      final result = await _repository.endSessionEarly(currentSession!.id);
      _applyTurnResult(result);
    } catch (e) {
      errorMessageAr = e.toString();
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  void _applyTurnResult(InterviewTurnResult result) {
    currentSession = result.session;
    sessionEnded = result.isSessionEnded;
    lastRiskAssessmentId = result.riskAssessmentId;

    if (result.botMessageAr != null) {
      messages.add(
        ChatMessage(
          id: "bot-${DateTime.now().microsecondsSinceEpoch}",
          sender: "bot",
          messageTextAr: result.botMessageAr!,
          messageOrder: messages.length + 1,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  void reset() {
    currentSession = null;
    messages.clear();
    sessionEnded = false;
    lastRiskAssessmentId = null;
    errorMessageAr = null;
  }
}
