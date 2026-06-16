"""
Risk Assessment Logic - Step 3 implementation.

Implements the scoring model described in Step 1 Section 7, now driven by
the real (or lexicon-fallback) sentiment labels produced by the Sentiment
Analysis Engine and stored on `InterviewAnswer.sentiment_label` /
`sentiment_score`, plus disease-specific adjustments from the Disease
Knowledge Layer (`chronic_conditions.knowledge_config_json`).

    dimension_score = base_from_direct_answers(dimension)
                       + sentiment_contribution(dimension)
                       + disease_specific_adjustment(dimension)

A crisis-language flag (see `crisis_detection.py`) always forces Risk Level 5,
regardless of the computed composite score, per Step 1 Section 7.5.
"""

from __future__ import annotations

from decimal import Decimal

from sqlalchemy.orm import Session

from app.models import InterviewSession, PatientCondition, PatientProfile, RiskAssessment
from app.models.enums import QuestionCategory
from app.services.llm_wrapper import generate_risk_explanation_ar

WEIGHTS = {
    "anxiety": Decimal("0.20"),
    "stress": Decimal("0.20"),
    "sadness": Decimal("0.15"),
    "burnout": Decimal("0.20"),
    "sleep": Decimal("0.125"),
    "adherence": Decimal("0.125"),
}

# Maps sentiment labels produced by the Sentiment Engine onto the six
# tracked risk dimensions. "frustration" is distributed across stress
# and burnout, as described informally in Step 1.
SENTIMENT_DIMENSION_WEIGHTS: dict[str, dict[str, Decimal]] = {
    "anxiety": {"anxiety": Decimal("1.0")},
    "stress": {"stress": Decimal("1.0")},
    "sadness": {"sadness": Decimal("1.0")},
    "burnout": {"burnout": Decimal("1.0")},
    "frustration": {"stress": Decimal("0.5"), "burnout": Decimal("0.5")},
    "positive": {},  # positive answers reduce risk implicitly by not contributing
    "neutral": {},
}

DISEASE_ADJUSTMENT_BOOST = Decimal("1.0")  # added to a dimension when a disease-specific pattern is triggered


def compute_risk_assessment(
    db: Session, session: InterviewSession, profile: PatientProfile, crisis_detected: bool = False
) -> RiskAssessment:
    dimension_totals: dict[str, Decimal] = {
        "anxiety": Decimal("0"),
        "stress": Decimal("0"),
        "sadness": Decimal("0"),
        "burnout": Decimal("0"),
    }
    text_answer_count = 0

    sleep_quality_raw_values: list[Decimal] = []
    adherence_raw_values: list[Decimal] = []

    emotion_label_counts: dict[str, int] = {}

    for answer in session.answers:
        category = answer.interview_question.category if answer.interview_question else None

        if answer.answer_text_ar:
            text_answer_count += 1

            label = answer.sentiment_label or "neutral"
            score = Decimal(str(answer.sentiment_score)) if answer.sentiment_score is not None else Decimal("0")
            emotion_label_counts[label] = emotion_label_counts.get(label, 0) + 1

            for dim, weight in SENTIMENT_DIMENSION_WEIGHTS.get(label, {}).items():
                dimension_totals[dim] += score * Decimal("10") * weight

        if answer.answer_value_numeric is not None:
            if category == QuestionCategory.sleep:
                sleep_quality_raw_values.append(answer.answer_value_numeric)
            elif category == QuestionCategory.adherence:
                adherence_raw_values.append(answer.answer_value_numeric)

    divisor = max(text_answer_count, 1)
    anxiety = min(dimension_totals["anxiety"] / divisor, Decimal("10"))
    stress = min(dimension_totals["stress"] / divisor, Decimal("10"))
    sadness = min(dimension_totals["sadness"] / divisor, Decimal("10"))
    burnout = min(dimension_totals["burnout"] / divisor, Decimal("10"))

    # Scale questions are assumed to be on a 1-5 scale -> rescale to 0-10 (higher = better).
    if sleep_quality_raw_values:
        avg_sleep = sum(sleep_quality_raw_values) / len(sleep_quality_raw_values)
        sleep_quality_score = avg_sleep * Decimal("2")
    else:
        sleep_quality_score = Decimal("6")  # neutral default

    if adherence_raw_values:
        avg_adherence = sum(adherence_raw_values) / len(adherence_raw_values)
        adherence_score = avg_adherence * Decimal("2")
    else:
        adherence_score = Decimal("6")  # neutral default

    # ------------------------------------------------------------------
    # Disease-specific adjustment (Disease Knowledge Layer)
    # ------------------------------------------------------------------
    disease_adjustments: list[str] = []
    conditions = db.query(PatientCondition).filter(PatientCondition.patient_profile_id == profile.id).all()

    DIM_BY_CATEGORY = {
        "anxiety": "anxiety",
        "stress": "stress",
        "sadness": "sadness",
        "burnout": "burnout",
    }

    for pc in conditions:
        config = pc.chronic_condition.knowledge_config_json or {}
        emotional_patterns = config.get("emotional_patterns", {})

        for pattern_name, pattern_cfg in emotional_patterns.items():
            target_dim = DIM_BY_CATEGORY.get(pattern_name)
            if target_dim is None:
                continue

            count_for_pattern = emotion_label_counts.get(pattern_name, 0)
            if count_for_pattern >= 1:
                if target_dim == "anxiety":
                    anxiety = min(anxiety + DISEASE_ADJUSTMENT_BOOST, Decimal("10"))
                elif target_dim == "stress":
                    stress = min(stress + DISEASE_ADJUSTMENT_BOOST, Decimal("10"))
                elif target_dim == "sadness":
                    sadness = min(sadness + DISEASE_ADJUSTMENT_BOOST, Decimal("10"))
                elif target_dim == "burnout":
                    burnout = min(burnout + DISEASE_ADJUSTMENT_BOOST, Decimal("10"))

                disease_adjustments.append(f"{pc.chronic_condition.code}_{pattern_name}_boost")

    # ------------------------------------------------------------------
    # Composite score
    # ------------------------------------------------------------------
    composite = (
        WEIGHTS["anxiety"] * anxiety
        + WEIGHTS["stress"] * stress
        + WEIGHTS["sadness"] * sadness
        + WEIGHTS["burnout"] * burnout
        + WEIGHTS["sleep"] * (Decimal("10") - sleep_quality_score)
        + WEIGHTS["adherence"] * (Decimal("10") - adherence_score)
    )
    composite_score = (composite * Decimal("10")).quantize(Decimal("0.01"))  # scale to 0-100

    risk_level, trend_note = _map_to_risk_level(db, profile, composite_score, crisis_detected)

    explanation_factors = {
        "composite_score": float(composite_score),
        "dimension_scores": {
            "anxiety": float(anxiety),
            "stress": float(stress),
            "sadness": float(sadness),
            "burnout": float(burnout),
            "sleep_quality": float(sleep_quality_score),
            "adherence": float(adherence_score),
        },
        "emotion_label_counts": emotion_label_counts,
        "trend": trend_note,
        "disease_adjustments_applied": disease_adjustments,
        "crisis_language_detected": crisis_detected,
        "method": "step3_sentiment_driven",
    }

    template_explanation_ar = _build_explanation_ar(risk_level, explanation_factors, crisis_detected)
    explanation_ar = generate_risk_explanation_ar(risk_level, explanation_factors, template_explanation_ar)

    risk_assessment = RiskAssessment(
        patient_profile_id=profile.id,
        interview_session_id=session.id,
        risk_level=risk_level,
        anxiety_score=anxiety.quantize(Decimal("0.01")),
        stress_score=stress.quantize(Decimal("0.01")),
        sadness_score=sadness.quantize(Decimal("0.01")),
        burnout_score=burnout.quantize(Decimal("0.01")),
        sleep_quality_score=sleep_quality_score.quantize(Decimal("0.01")),
        adherence_score=adherence_score.quantize(Decimal("0.01")),
        composite_score=composite_score,
        explanation_ar=explanation_ar,
        explanation_factors_json=explanation_factors,
    )
    db.add(risk_assessment)
    db.commit()
    db.refresh(risk_assessment)
    return risk_assessment


def _map_to_risk_level(
    db: Session, profile: PatientProfile, composite_score: Decimal, crisis_detected: bool
) -> tuple[int, str]:
    if crisis_detected:
        return 5, "crisis_language_detected"

    last_assessment = (
        db.query(RiskAssessment)
        .filter(RiskAssessment.patient_profile_id == profile.id)
        .order_by(RiskAssessment.created_at.desc())
        .first()
    )

    worsening = last_assessment is not None and composite_score >= last_assessment.composite_score
    return score_to_level(composite_score, worsening=worsening, has_history=last_assessment is not None)


def score_to_level(composite_score: Decimal, worsening: bool, has_history: bool) -> tuple[int, str]:
    """
    Pure mapping from a composite score (0-100) plus trend information to a
    risk level (1-5) and a short trend note, per Step 1 Section 7.5.

    This function is intentionally free of DB/ORM dependencies so it can be
    unit-tested directly.
    """
    if composite_score <= 20:
        return 1, "stable_or_improving"
    if composite_score <= 40:
        return (3, "worsening_trend") if worsening and has_history else (2, "stable")
    if composite_score <= 65:
        return (4, "worsening_trend") if worsening and has_history else (3, "stable")
    if composite_score <= 85:
        return 4, "elevated"
    return 5, "critical"


def _build_explanation_ar(risk_level: int, factors: dict, crisis_detected: bool) -> str:
    if crisis_detected:
        return (
            "لاحظنا في حديثك بعض العبارات التي تشير إلى أنك تمر بضغط نفسي شديد قد يتطلب "
            "تدخلاً سريعاً. نحن نهتم بسلامتك، ونشجعك بشدة على التواصل فوراً مع مختص في "
            "الصحة النفسية أو مع شخص تثق به أو مع خط الدعم النفسي المتاح في بلدك. "
            "أنت لست وحدك، وطلب المساعدة الآن خطوة مهمة وشجاعة."
        )

    level_text = {
        1: "مستوى 1 - حالة مستقرة",
        2: "مستوى 2 - قلق خفيف",
        3: "مستوى 3 - خطر متوسط",
        4: "مستوى 4 - خطر مرتفع",
        5: "مستوى 5 - يتطلب اهتماماً عاجلاً",
    }[risk_level]

    dims = factors["dimension_scores"]
    parts = []
    if dims["anxiety"] >= 5:
        parts.append("ارتفاع مستوى القلق")
    if dims["stress"] >= 5:
        parts.append("ارتفاع مستوى التوتر")
    if dims["sadness"] >= 5:
        parts.append("ظهور مؤشرات حزن")
    if dims["burnout"] >= 5:
        parts.append("ظهور علامات إرهاق نفسي")
    if dims["sleep_quality"] <= 5:
        parts.append("ضعف جودة النوم")
    if dims["adherence"] <= 5:
        parts.append("ضعف الالتزام بالعلاج")

    if factors.get("trend") == "worsening_trend":
        parts.append("استمرار هذا النمط منذ الجلسة السابقة")

    if not parts:
        reasons_text = "لم تظهر مؤشرات قلق واضحة في هذه الجلسة، ونتمنى أن تستمر بهذه الحالة الجيدة."
    else:
        reasons_text = "أهم المؤشرات التي بنينا عليها هذا التصنيف: " + "، ".join(parts) + "."

    return f"تم تصنيف حالتك ضمن ({level_text}). {reasons_text}"
