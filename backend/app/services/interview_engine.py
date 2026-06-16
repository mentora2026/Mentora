"""
Adaptive Interview Engine - Step 3 implementation.

Implements the rule-based core described in the Step 1 architecture, now
integrated with the Step 3 AI components:

- Context Manager (via `InterviewSession.context_state_json`)
- Question Selector (category prioritization using the Disease Knowledge Layer,
  with sentiment-driven escalation)
- Depth / Termination Controller
- Sentiment Analysis Engine (per-answer emotion labeling)
- Crisis Language Detection (safety override)
- LLM Wrapper (question rephrasing + session summarization)
"""

from __future__ import annotations

import uuid
from decimal import Decimal
from typing import Optional

from sqlalchemy.orm import Session
from sqlalchemy.orm.attributes import flag_modified

from app.core.config import settings
from app.models import (
    ChatbotConversation,
    InterviewAnswer,
    InterviewQuestion,
    InterviewSession,
    Notification,
    PatientCondition,
    PatientProfile,
    User,
)
from app.models.enums import ChatSender, NotificationType, QuestionCategory, SessionStatus, UserRole
from app.services.crisis_detection import contains_crisis_language
from app.services.llm_wrapper import generate_session_summary_ar, rephrase_question_ar
from app.services.sentiment_engine import sentiment_engine

# Default category exploration order when no disease-specific priority is configured.
DEFAULT_CATEGORY_ORDER = [
    QuestionCategory.general,
    QuestionCategory.sleep,
    QuestionCategory.adherence,
    QuestionCategory.anxiety,
    QuestionCategory.stress,
    QuestionCategory.sadness,
    QuestionCategory.burnout,
    QuestionCategory.social_isolation,
    QuestionCategory.adaptation,
]

# Maps Disease Knowledge Layer "emotional_patterns" keys (emotion labels) onto
# InterviewQuestion categories, used for escalation/follow-up.
EMOTION_TO_CATEGORY = {
    "anxiety": QuestionCategory.anxiety.value,
    "stress": QuestionCategory.stress.value,
    "sadness": QuestionCategory.sadness.value,
    "burnout": QuestionCategory.burnout.value,
}

CLOSING_MESSAGE_AR = (
    "شكراً لمشاركتك معي اليوم. لقد سجّلت إجاباتك وسأقوم بمراجعتها لتقديم بعض "
    "التوصيات التي قد تساعدك. أتمنى لك يوماً أفضل، ونلتقي في الجلسة القادمة بإذن الله."
)

CRISIS_ACK_MESSAGE_AR = (
    "أشعر بأن ما تمر به هذه اللحظة مهم جداً، وأريدك أن تعلم أنك لست وحدك. "
    "سأنهي هذه الجلسة الآن وسنقدم لك توصية بالتواصل مع شخص مختص يمكنه مساعدتك بشكل أفضل."
)


def build_priority_category_order(knowledge_configs: list[dict]) -> list[str]:
    """
    Pure function (Step 1 Section 5.2.2 / 6.4): merges the
    `priority_categories` lists from one or more Disease Knowledge Layer
    configs (one per chronic condition the patient has), preserving order and
    de-duplicating, then appends any remaining categories from
    `DEFAULT_CATEGORY_ORDER` that weren't already included.

    Free of DB/ORM dependencies so it can be unit-tested directly with plain
    dicts representing `chronic_conditions.knowledge_config_json`.
    """
    ordered: list[str] = []
    for config in knowledge_configs:
        for cat in (config or {}).get("priority_categories", []):
            if cat not in ordered:
                ordered.append(cat)

    for cat in DEFAULT_CATEGORY_ORDER:
        if cat.value not in ordered:
            ordered.append(cat.value)

    return ordered


def top_emotions(emotion_history: list[str], limit: int = 2) -> list[str]:
    """
    Pure function: returns the `limit` most frequent non-neutral emotion
    labels from a session's emotion history, most frequent first.
    Used for LLM-assisted session summaries (Step 1 Section 9.1).
    """
    counts: dict[str, int] = {}
    for emotion in emotion_history:
        if emotion in ("neutral",):
            continue
        counts[emotion] = counts.get(emotion, 0) + 1

    sorted_emotions = sorted(counts.items(), key=lambda item: item[1], reverse=True)
    return [emotion for emotion, _ in sorted_emotions[:limit]]


class InterviewEngine:
    def __init__(self, db: Session):
        self.db = db

    # ------------------------------------------------------------------
    # Context helpers
    # ------------------------------------------------------------------
    def _get_priority_categories(self, profile: PatientProfile) -> list[str]:
        """
        Build the ordered list of categories to explore, based on the patient's
        chronic conditions' `knowledge_config_json.priority_categories`
        (Disease Knowledge Layer), falling back to a sensible default order.
        """
        conditions = (
            self.db.query(PatientCondition)
            .filter(PatientCondition.patient_profile_id == profile.id)
            .all()
        )

        knowledge_configs = [pc.chronic_condition.knowledge_config_json or {} for pc in conditions]
        return build_priority_category_order(knowledge_configs)

    def _condition_ids(self, profile: PatientProfile) -> list[uuid.UUID]:
        return [
            pc.chronic_condition_id
            for pc in self.db.query(PatientCondition)
            .filter(PatientCondition.patient_profile_id == profile.id)
            .all()
        ]

    # ------------------------------------------------------------------
    # Question selection
    # ------------------------------------------------------------------
    def _find_question_for_category(
        self, category: str, condition_ids: list[uuid.UUID]
    ) -> Optional[InterviewQuestion]:
        question = (
            self.db.query(InterviewQuestion)
            .filter(
                InterviewQuestion.category == category,
                InterviewQuestion.chronic_condition_id.in_(condition_ids) if condition_ids else False,
            )
            .first()
        )
        if question is None:
            question = (
                self.db.query(InterviewQuestion)
                .filter(
                    InterviewQuestion.category == category,
                    InterviewQuestion.chronic_condition_id.is_(None),
                )
                .first()
            )
        return question

    def _select_next_question(
        self, profile: PatientProfile, context: dict
    ) -> Optional[InterviewQuestion]:
        covered_categories = context.get("covered_categories", [])
        condition_ids = self._condition_ids(profile)

        # 1) Escalation takes priority: if the previous answer triggered a
        #    disease-aware emotional pattern, probe deeper into that category
        #    next (even if a "first pass" of categories isn't finished yet).
        if context.get("escalation_pending"):
            escalation_category = context.get("escalation_category")
            question = self._find_question_for_category(escalation_category, condition_ids)
            if question is not None:
                context["escalation_pending"] = False
                return question
            context["escalation_pending"] = False

        # 2) Normal priority-ordered selection, skipping covered categories.
        for category in self._get_priority_categories(profile):
            if category in covered_categories:
                continue

            question = self._find_question_for_category(category, condition_ids)
            if question is not None:
                return question

        return None

    # ------------------------------------------------------------------
    # Session lifecycle
    # ------------------------------------------------------------------
    def start_session(self, session: InterviewSession, profile: PatientProfile) -> str:
        """
        Selects and asks the first question. Returns the bot message (Arabic).
        """
        context = {"covered_categories": [], "answers_count": 0, "emotion_history": []}

        question = self._select_next_question(profile, context)

        if question is None:
            # No questions configured at all - end immediately.
            return self._close_session(session, profile, context)

        context["current_question_id"] = str(question.id)
        context["current_question_category"] = question.category.value
        session.context_state_json = context
        flag_modified(session, "context_state_json")

        bot_text = rephrase_question_ar(question.question_text_ar)
        self._add_chat_message(session, ChatSender.bot, bot_text)
        self.db.add(session)
        self.db.commit()
        return bot_text

    def submit_answer(
        self,
        session: InterviewSession,
        profile: PatientProfile,
        answer_text_ar: Optional[str],
        answer_value_numeric: Optional[Decimal],
    ) -> tuple[Optional[str], bool]:
        """
        Records the patient's answer to the current question, runs sentiment
        analysis + crisis detection, then either selects the next question
        (possibly escalating) or ends the session.

        Returns: (bot_message_ar, is_session_ended)
        """
        context = session.context_state_json or {"covered_categories": [], "answers_count": 0, "emotion_history": []}
        context.setdefault("emotion_history", [])

        current_question_id = context.get("current_question_id")
        current_question_category = context.get("current_question_category", QuestionCategory.general.value)
        current_question_text = context.get("current_question_text")

        question_obj = None
        if current_question_id:
            question_obj = self.db.query(InterviewQuestion).filter(InterviewQuestion.id == current_question_id).first()

        question_snapshot = (
            question_obj.question_text_ar if question_obj else (current_question_text or "")
        )

        # Record patient's message in the chat log
        if answer_text_ar:
            self._add_chat_message(session, ChatSender.patient, answer_text_ar)
        elif answer_value_numeric is not None:
            self._add_chat_message(session, ChatSender.patient, str(answer_value_numeric))

        # --------------------------------------------------------------
        # Sentiment Analysis Engine (Step 3)
        # --------------------------------------------------------------
        sentiment_label: Optional[str] = None
        sentiment_score: Optional[Decimal] = None
        if answer_text_ar:
            result = sentiment_engine.analyze(answer_text_ar)
            sentiment_label = result.label
            sentiment_score = Decimal(str(round(result.score, 3)))
            context["emotion_history"].append(sentiment_label)

        # --------------------------------------------------------------
        # Crisis Language Detection (Step 3 safety override)
        # --------------------------------------------------------------
        if answer_text_ar and contains_crisis_language(answer_text_ar):
            context["crisis_detected"] = True

        # Persist the structured answer.
        answer_row = InterviewAnswer(
            interview_session_id=session.id,
            interview_question_id=question_obj.id if question_obj else None,
            question_text_ar_snapshot=question_snapshot,
            answer_text_ar=answer_text_ar,
            answer_value_numeric=answer_value_numeric,
            sentiment_label=sentiment_label,
            sentiment_score=sentiment_score,
            sequence_order=context["answers_count"] + 1,
        )
        self.db.add(answer_row)

        # Update context
        covered = set(context.get("covered_categories", []))
        covered.add(current_question_category)
        context["covered_categories"] = list(covered)
        context["answers_count"] = context["answers_count"] + 1

        session.total_questions_asked = context["answers_count"]

        # --------------------------------------------------------------
        # Escalation logic: if this answer strongly matches a disease-aware
        # emotional pattern, prioritize that category's follow-up question next.
        # --------------------------------------------------------------
        if sentiment_label and sentiment_score is not None:
            self._maybe_set_escalation(profile, context, sentiment_label, sentiment_score)

        # --------------------------------------------------------------
        # Crisis override: end the session immediately and supportively.
        # --------------------------------------------------------------
        if context.get("crisis_detected"):
            bot_message = self._close_session(session, profile, context)
            return bot_message, True

        # Termination check
        if self._should_terminate(context):
            bot_message = self._close_session(session, profile, context)
            return bot_message, True

        # Select next question
        next_question = self._select_next_question(profile, context)
        if next_question is None:
            bot_message = self._close_session(session, profile, context)
            return bot_message, True

        context["current_question_id"] = str(next_question.id)
        context["current_question_category"] = next_question.category.value
        session.context_state_json = context
        flag_modified(session, "context_state_json")

        # Personalize phrasing if this question is an escalation follow-up.
        context_hint = None
        if next_question.category.value == context.get("escalation_category") and answer_text_ar:
            context_hint = answer_text_ar

        bot_text = rephrase_question_ar(next_question.question_text_ar, context_hint=context_hint)
        self._add_chat_message(session, ChatSender.bot, bot_text)
        self.db.add(session)
        self.db.commit()
        return bot_text, False

    def end_session_early(self, session: InterviewSession, profile: PatientProfile) -> str:
        context = session.context_state_json or {"covered_categories": [], "answers_count": 0, "emotion_history": []}
        return self._close_session(session, profile, context)

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    def _maybe_set_escalation(
        self, profile: PatientProfile, context: dict, sentiment_label: str, sentiment_score: Decimal
    ) -> None:
        """
        Checks the patient's Disease Knowledge Layer `emotional_patterns` config.
        If the detected emotion exceeds the configured confidence threshold and
        maps to a question category, mark that category for priority exploration
        on the next turn (Question Selector escalation - Step 1 Section 5.2.2/6.4).
        """
        if sentiment_label not in EMOTION_TO_CATEGORY:
            return

        if float(sentiment_score) < settings.SENTIMENT_EMOTION_THRESHOLD:
            return

        target_category = EMOTION_TO_CATEGORY[sentiment_label]
        covered = context.get("covered_categories", [])

        follow_up_category = target_category
        conditions = self.db.query(PatientCondition).filter(PatientCondition.patient_profile_id == profile.id).all()
        for pc in conditions:
            config = pc.chronic_condition.knowledge_config_json or {}
            emotional_patterns = config.get("emotional_patterns", {})
            pattern_cfg = emotional_patterns.get(sentiment_label)
            if pattern_cfg:
                follow_up_category = pattern_cfg.get("follow_up_category", target_category)
                break

        if follow_up_category in covered:
            return

        context["escalation_category"] = follow_up_category
        context["escalation_pending"] = True

    def _should_terminate(self, context: dict) -> bool:
        answers_count = context.get("answers_count", 0)
        covered = context.get("covered_categories", [])

        if answers_count >= settings.INTERVIEW_MAX_QUESTIONS:
            return True

        # All known categories covered AND minimum reached AND no pending
        # escalation -> "stable" early exit
        if (
            answers_count >= settings.INTERVIEW_MIN_QUESTIONS
            and len(covered) >= len(DEFAULT_CATEGORY_ORDER)
            and not context.get("escalation_pending")
        ):
            return True

        return False

    def _add_chat_message(self, session: InterviewSession, sender: ChatSender, text_ar: str) -> None:
        next_order = len(session.conversation) + 1
        message = ChatbotConversation(
            interview_session_id=session.id,
            sender=sender,
            message_text_ar=text_ar,
            message_order=next_order,
        )
        self.db.add(message)
        session.conversation.append(message)

    def _close_session(self, session: InterviewSession, profile: PatientProfile, context: dict) -> str:
        from app.services.recommendation_engine import select_recommendations
        from app.services.risk_engine import compute_risk_assessment

        crisis_detected = bool(context.get("crisis_detected"))

        session.status = SessionStatus.completed
        session.context_state_json = context
        flag_modified(session, "context_state_json")

        from sqlalchemy import func as sa_func

        session.ended_at = sa_func.now()

        closing_text = CRISIS_ACK_MESSAGE_AR if crisis_detected else CLOSING_MESSAGE_AR
        self._add_chat_message(session, ChatSender.bot, closing_text)

        # LLM-assisted session summary (Step 3)
        qa_pairs = [
            (a.question_text_ar_snapshot, a.answer_text_ar)
            for a in session.answers
            if a.answer_text_ar
        ]
        emotion_history = context.get("emotion_history", [])
        dominant_emotions = top_emotions(emotion_history)
        session.session_summary_ar = generate_session_summary_ar(qa_pairs, dominant_emotions)

        # Risk Classification (Step 3: sentiment-driven)
        risk_assessment = compute_risk_assessment(self.db, session, profile, crisis_detected=crisis_detected)
        session.risk_assessment_id = risk_assessment.id

        self.db.add(session)
        self.db.commit()
        self.db.refresh(session)

        # Recommendation Engine
        select_recommendations(self.db, profile, risk_assessment)

        # Admin alert on crisis / Level 5 (Step 1 Section 7.5 / 9.2)
        if crisis_detected or risk_assessment.risk_level == 5:
            self._notify_admins_of_critical_risk(profile, risk_assessment.risk_level)

        return closing_text

    def _notify_admins_of_critical_risk(self, profile: PatientProfile, risk_level: int) -> None:
        admins = self.db.query(User).filter(User.role.in_([UserRole.admin, UserRole.clinical_supervisor])).all()
        patient_name = profile.user.full_name if profile.user else "مستخدم"

        for admin in admins:
            notification = Notification(
                user_id=admin.id,
                type=NotificationType.risk_alert_admin,
                title_ar="تنبيه: حالة تتطلب اهتماماً عاجلاً",
                body_ar=(
                    f"تم تصنيف حالة المريض ({patient_name}) ضمن المستوى {risk_level} "
                    "بعد آخر جلسة محادثة. يرجى المراجعة في أقرب وقت ممكن."
                ),
            )
            self.db.add(notification)

        self.db.commit()
