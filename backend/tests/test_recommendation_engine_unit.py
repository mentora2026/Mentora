"""
Unit tests for the Recommendation Engine's pure selection logic
(Step 1 Section 8.2). These tests require no database connection.
"""

import uuid

from app.services.recommendation_engine import RecommendationCandidate, filter_and_score_candidates

DIABETES_ID = uuid.uuid4()
CANCER_ID = uuid.uuid4()

GENERIC_MOTIVATIONAL = RecommendationCandidate(id=uuid.uuid4(), applicable_risk_levels=[1, 2], chronic_condition_id=None)
GENERIC_BREATHING = RecommendationCandidate(id=uuid.uuid4(), applicable_risk_levels=[2, 3, 4], chronic_condition_id=None)
GENERIC_PROFESSIONAL_HELP = RecommendationCandidate(
    id=uuid.uuid4(), applicable_risk_levels=[4, 5], chronic_condition_id=None
)
DIABETES_SPECIFIC = RecommendationCandidate(id=uuid.uuid4(), applicable_risk_levels=[2, 3], chronic_condition_id=DIABETES_ID)
CANCER_SPECIFIC = RecommendationCandidate(id=uuid.uuid4(), applicable_risk_levels=[2, 3], chronic_condition_id=CANCER_ID)


class TestFilterAndScoreCandidates:
    def test_filters_by_risk_level(self):
        candidates = [GENERIC_MOTIVATIONAL, GENERIC_BREATHING]
        selected = filter_and_score_candidates(
            candidates, risk_level=1, patient_condition_ids=[], recently_delivered_ids=set()
        )
        # Only GENERIC_MOTIVATIONAL applies to risk level 1.
        assert selected == [GENERIC_MOTIVATIONAL.id]

    def test_excludes_disease_specific_for_other_diseases(self):
        candidates = [DIABETES_SPECIFIC, GENERIC_BREATHING]
        selected = filter_and_score_candidates(
            candidates, risk_level=2, patient_condition_ids=[CANCER_ID], recently_delivered_ids=set()
        )
        assert DIABETES_SPECIFIC.id not in selected
        assert GENERIC_BREATHING.id in selected

    def test_includes_disease_specific_for_matching_disease(self):
        candidates = [DIABETES_SPECIFIC, GENERIC_BREATHING]
        selected = filter_and_score_candidates(
            candidates, risk_level=2, patient_condition_ids=[DIABETES_ID], recently_delivered_ids=set()
        )
        assert DIABETES_SPECIFIC.id in selected
        assert GENERIC_BREATHING.id in selected

    def test_disease_specific_ranked_above_generic(self):
        candidates = [GENERIC_BREATHING, DIABETES_SPECIFIC]
        selected = filter_and_score_candidates(
            candidates, risk_level=2, patient_condition_ids=[DIABETES_ID], recently_delivered_ids=set(), top_n=1
        )
        # With top_n=1, the disease-specific recommendation should win even
        # though it appears second in the input list.
        assert selected == [DIABETES_SPECIFIC.id]

    def test_excludes_recently_delivered(self):
        candidates = [GENERIC_MOTIVATIONAL]
        selected = filter_and_score_candidates(
            candidates,
            risk_level=1,
            patient_condition_ids=[],
            recently_delivered_ids={GENERIC_MOTIVATIONAL.id},
        )
        assert selected == []

    def test_respects_top_n_limit(self):
        candidates = [GENERIC_MOTIVATIONAL, GENERIC_BREATHING, DIABETES_SPECIFIC, CANCER_SPECIFIC]
        # All applicable at risk level 2, patient has both conditions.
        selected = filter_and_score_candidates(
            candidates,
            risk_level=2,
            patient_condition_ids=[DIABETES_ID, CANCER_ID],
            recently_delivered_ids=set(),
            top_n=3,
        )
        assert len(selected) == 3

    def test_critical_risk_prioritizes_professional_help(self):
        candidates = [GENERIC_PROFESSIONAL_HELP]
        selected = filter_and_score_candidates(
            candidates, risk_level=5, patient_condition_ids=[], recently_delivered_ids=set()
        )
        assert selected == [GENERIC_PROFESSIONAL_HELP.id]

    def test_no_matching_candidates_returns_empty(self):
        candidates = [GENERIC_MOTIVATIONAL]  # only applies to levels 1-2
        selected = filter_and_score_candidates(
            candidates, risk_level=5, patient_condition_ids=[], recently_delivered_ids=set()
        )
        assert selected == []

    def test_empty_candidate_list(self):
        selected = filter_and_score_candidates(
            [], risk_level=3, patient_condition_ids=[], recently_delivered_ids=set()
        )
        assert selected == []
