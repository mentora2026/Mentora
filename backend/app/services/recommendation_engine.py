"""
Recommendation Engine Logic - Step 2 implementation.

Implements a simplified version of the selection algorithm described in
Step 1 Section 8: matches active `Recommendation` catalog entries to the
patient's risk level and chronic condition(s), avoiding recently delivered
items, and stores the result in `patient_recommendations`.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Optional
from uuid import UUID

from sqlalchemy.orm import Session

from app.models import (
    PatientCondition,
    PatientProfile,
    PatientRecommendation,
    Recommendation,
    RiskAssessment,
)

TOP_N_RECOMMENDATIONS = 3
RECENTLY_DELIVERED_WINDOW_DAYS = 7


@dataclass(frozen=True)
class RecommendationCandidate:
    """
    Lightweight, ORM-free view of a `Recommendation` row used by
    `filter_and_score_candidates` so the selection logic can be unit-tested
    without a database.
    """

    id: UUID
    applicable_risk_levels: list[int]
    chronic_condition_id: Optional[UUID]


def filter_and_score_candidates(
    candidates: list[RecommendationCandidate],
    risk_level: int,
    patient_condition_ids: list[UUID],
    recently_delivered_ids: set[UUID],
    top_n: int = TOP_N_RECOMMENDATIONS,
) -> list[UUID]:
    """
    Pure selection logic (Step 1 Section 8.2):

    - Excludes recommendations delivered within the recent window.
    - Excludes recommendations whose `applicable_risk_levels` doesn't include
      the patient's current risk level.
    - Excludes disease-specific recommendations for diseases the patient
      doesn't have.
    - Scores disease-specific recommendations higher than generic ones.
    - Returns up to `top_n` recommendation IDs, highest score first, in
      catalog order for ties (stable sort).
    """
    scored: list[tuple[int, RecommendationCandidate]] = []

    for candidate in candidates:
        if candidate.id in recently_delivered_ids:
            continue
        if risk_level not in (candidate.applicable_risk_levels or []):
            continue
        if candidate.chronic_condition_id is not None and candidate.chronic_condition_id not in patient_condition_ids:
            continue

        score = 1
        if candidate.chronic_condition_id is not None:
            score += 1  # disease-specific content is prioritized over generic content

        scored.append((score, candidate))

    scored.sort(key=lambda item: item[0], reverse=True)
    return [candidate.id for _, candidate in scored[:top_n]]


def select_recommendations(db: Session, profile: PatientProfile, risk_assessment: RiskAssessment) -> list[PatientRecommendation]:
    condition_ids = [
        pc.chronic_condition_id
        for pc in db.query(PatientCondition).filter(PatientCondition.patient_profile_id == profile.id).all()
    ]

    recently_delivered_ids = {
        pr.recommendation_id
        for pr in db.query(PatientRecommendation)
        .filter(
            PatientRecommendation.patient_profile_id == profile.id,
            PatientRecommendation.delivered_at >= datetime.now(timezone.utc) - timedelta(days=RECENTLY_DELIVERED_WINDOW_DAYS),
        )
        .all()
    }

    db_candidates = db.query(Recommendation).filter(Recommendation.is_active.is_(True)).all()
    candidates_by_id = {rec.id: rec for rec in db_candidates}

    candidates = [
        RecommendationCandidate(
            id=rec.id,
            applicable_risk_levels=rec.applicable_risk_levels or [],
            chronic_condition_id=rec.chronic_condition_id,
        )
        for rec in db_candidates
    ]

    selected_ids = filter_and_score_candidates(
        candidates=candidates,
        risk_level=risk_assessment.risk_level,
        patient_condition_ids=condition_ids,
        recently_delivered_ids=recently_delivered_ids,
    )

    created: list[PatientRecommendation] = []
    for rec_id in selected_ids:
        rec = candidates_by_id[rec_id]
        pr = PatientRecommendation(
            patient_profile_id=profile.id,
            recommendation_id=rec.id,
            risk_assessment_id=risk_assessment.id,
        )
        db.add(pr)
        created.append(pr)

    db.commit()
    return created
