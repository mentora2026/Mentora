import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict

from app.models.enums import ChatSender, SessionStatus, TriggerType


class InterviewStartRequest(BaseModel):
    trigger_type: TriggerType = TriggerType.manual


class ChatMessageOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    sender: ChatSender
    message_text_ar: str
    message_order: int
    created_at: datetime


class InterviewSessionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    status: SessionStatus
    trigger_type: TriggerType
    started_at: datetime
    ended_at: Optional[datetime] = None
    total_questions_asked: int
    session_summary_ar: Optional[str] = None


class InterviewSessionDetailOut(InterviewSessionOut):
    conversation: list[ChatMessageOut] = []


class InterviewAnswerSubmit(BaseModel):
    """
    Patient's reply to the current question.
    - answer_text_ar: free-text Arabic reply (for open_text questions)
    - answer_value_numeric: numeric reply (for scale_1_5 / yes_no / multiple_choice questions)
    """

    answer_text_ar: Optional[str] = None
    answer_value_numeric: Optional[Decimal] = None


class InterviewTurnResponse(BaseModel):
    """
    Response returned after starting a session or submitting an answer.
    Either contains the next bot message (question) or signals session end.
    """

    session: InterviewSessionOut
    bot_message_ar: Optional[str] = None
    is_session_ended: bool = False
    risk_assessment_id: Optional[uuid.UUID] = None
