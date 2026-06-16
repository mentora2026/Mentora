from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.api.deps import get_current_patient_profile
from app.core.database import get_db
from app.models import InterviewSession, PatientProfile
from app.models.enums import SessionStatus
from app.schemas.interview import (
    InterviewAnswerSubmit,
    InterviewSessionDetailOut,
    InterviewSessionOut,
    InterviewStartRequest,
    InterviewTurnResponse,
)
from app.services.interview_engine import InterviewEngine

router = APIRouter(prefix="/interviews", tags=["Adaptive Interview"])


@router.post("/start", response_model=InterviewTurnResponse, status_code=status.HTTP_201_CREATED)
def start_interview(
    payload: InterviewStartRequest,
    profile: PatientProfile = Depends(get_current_patient_profile),
    db: Session = Depends(get_db),
):
    """
    Start a new Adaptive Interview session.

    The Adaptive Interview Engine selects the first question based on the
    patient's chronic condition(s) (Disease Knowledge Layer priority
    categories) and returns it as `bot_message_ar`.

    Fails with `409 Conflict` if the patient already has an in-progress
    session - it must be completed via `/answer` or `/end` first.

    In the rare case where no questions are configured at all, the session
    ends immediately (`is_session_ended=true`) and a risk assessment is still
    produced from the (empty) session.
    """
    existing_active = (
        db.query(InterviewSession)
        .filter(
            InterviewSession.patient_profile_id == profile.id,
            InterviewSession.status == SessionStatus.in_progress,
        )
        .first()
    )
    if existing_active:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="توجد جلسة تفاعلية مفتوحة بالفعل، يرجى إكمالها أولاً",
        )

    session = InterviewSession(patient_profile_id=profile.id, trigger_type=payload.trigger_type)
    db.add(session)
    db.commit()
    db.refresh(session)

    engine = InterviewEngine(db)
    bot_message = engine.start_session(session, profile)

    db.refresh(session)
    is_ended = session.status == SessionStatus.completed

    return InterviewTurnResponse(
        session=InterviewSessionOut.model_validate(session),
        bot_message_ar=bot_message,
        is_session_ended=is_ended,
        risk_assessment_id=session.risk_assessment_id,
    )


@router.post("/{session_id}/answer", response_model=InterviewTurnResponse)
def submit_answer(
    session_id: str,
    payload: InterviewAnswerSubmit,
    profile: PatientProfile = Depends(get_current_patient_profile),
    db: Session = Depends(get_db),
):
    """
    Submit the patient's answer to the current question and advance the
    interview.

    Send `answer_text_ar` for open-ended questions (the Sentiment Analysis
    Engine classifies the emotion: anxiety/stress/sadness/burnout/frustration/
    positive/neutral) or `answer_value_numeric` for `scale_1_5` /
    `yes_no` / `multiple_choice` questions.

    Behavior:
    - If the detected emotion strongly matches a Disease Knowledge Layer
      pattern for the patient's condition(s), the Question Selector
      **escalates** - the next question probes deeper into the related
      category.
    - If the answer contains explicit crisis/self-harm language, the session
      ends immediately (`is_session_ended=true`), `risk_assessment_id` points
      to a **Level 5** assessment, a `professional_help` recommendation is
      created, and admins receive a `risk_alert_admin` notification.
    - Otherwise, when the Depth/Termination Controller decides the session is
      complete (minimum questions reached and all priority categories
      covered, or the maximum question count is hit), `is_session_ended=true`
      and `risk_assessment_id` is populated.
    - While `is_session_ended=false`, `bot_message_ar` contains the next
      question.
    """
    session = _get_owned_session(db, session_id, profile)

    if session.status != SessionStatus.in_progress:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="هذه الجلسة منتهية بالفعل")

    if payload.answer_text_ar is None and payload.answer_value_numeric is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="يرجى إرسال إجابة نصية أو رقمية")

    engine = InterviewEngine(db)
    bot_message, is_ended = engine.submit_answer(
        session, profile, payload.answer_text_ar, payload.answer_value_numeric
    )

    db.refresh(session)

    return InterviewTurnResponse(
        session=InterviewSessionOut.model_validate(session),
        bot_message_ar=bot_message,
        is_session_ended=is_ended,
        risk_assessment_id=session.risk_assessment_id,
    )


@router.post("/{session_id}/end", response_model=InterviewTurnResponse)
def end_interview(
    session_id: str,
    profile: PatientProfile = Depends(get_current_patient_profile),
    db: Session = Depends(get_db),
):
    """
    End an in-progress interview session early (e.g., the patient wants to
    stop before the engine would normally terminate it).

    A risk assessment and recommendations are still generated from whatever
    answers were collected before ending.
    """
    session = _get_owned_session(db, session_id, profile)

    if session.status != SessionStatus.in_progress:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="هذه الجلسة منتهية بالفعل")

    engine = InterviewEngine(db)
    bot_message = engine.end_session_early(session, profile)

    db.refresh(session)

    return InterviewTurnResponse(
        session=InterviewSessionOut.model_validate(session),
        bot_message_ar=bot_message,
        is_session_ended=True,
        risk_assessment_id=session.risk_assessment_id,
    )


@router.get("/history", response_model=list[InterviewSessionOut])
def interview_history(
    profile: PatientProfile = Depends(get_current_patient_profile),
    db: Session = Depends(get_db),
):
    sessions = (
        db.query(InterviewSession)
        .filter(InterviewSession.patient_profile_id == profile.id)
        .order_by(InterviewSession.started_at.desc())
        .all()
    )
    return sessions


@router.get("/{session_id}", response_model=InterviewSessionDetailOut)
def get_interview(
    session_id: str,
    profile: PatientProfile = Depends(get_current_patient_profile),
    db: Session = Depends(get_db),
):
    session = _get_owned_session(db, session_id, profile)
    return session


@router.get("/{session_id}/conversation", response_model=InterviewSessionDetailOut)
def get_interview_conversation(
    session_id: str,
    profile: PatientProfile = Depends(get_current_patient_profile),
    db: Session = Depends(get_db),
):
    session = _get_owned_session(db, session_id, profile)
    return session


def _get_owned_session(db: Session, session_id: str, profile: PatientProfile) -> InterviewSession:
    session = (
        db.query(InterviewSession)
        .options(joinedload(InterviewSession.conversation))
        .filter(InterviewSession.id == session_id, InterviewSession.patient_profile_id == profile.id)
        .first()
    )
    if session is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="الجلسة غير موجودة")
    return session
