"""
Unit tests for the Risk Assessment Logic's pure helper functions
(Step 1 Section 7 / 7.5). These tests require no database connection.
"""

from decimal import Decimal

from app.services.risk_engine import _build_explanation_ar, score_to_level


# ---------------------------------------------------------------------------
# score_to_level
# ---------------------------------------------------------------------------
class TestScoreToLevel:
    def test_low_score_is_stable(self):
        level, trend = score_to_level(Decimal("10"), worsening=False, has_history=False)
        assert level == 1
        assert trend == "stable_or_improving"

    def test_boundary_at_20_is_stable(self):
        level, _ = score_to_level(Decimal("20"), worsening=False, has_history=False)
        assert level == 1

    def test_mild_concern_without_history(self):
        level, trend = score_to_level(Decimal("30"), worsening=False, has_history=False)
        assert level == 2
        assert trend == "stable"

    def test_mild_concern_escalates_to_moderate_when_worsening(self):
        level, trend = score_to_level(Decimal("30"), worsening=True, has_history=True)
        assert level == 3
        assert trend == "worsening_trend"

    def test_worsening_without_history_does_not_escalate(self):
        # `worsening=True` with `has_history=False` shouldn't happen in
        # practice (no prior assessment to compare against), but the function
        # must not escalate without history.
        level, trend = score_to_level(Decimal("30"), worsening=True, has_history=False)
        assert level == 2
        assert trend == "stable"

    def test_moderate_risk_without_history(self):
        level, trend = score_to_level(Decimal("55"), worsening=False, has_history=True)
        assert level == 3
        assert trend == "stable"

    def test_moderate_escalates_to_high_when_worsening(self):
        level, trend = score_to_level(Decimal("55"), worsening=True, has_history=True)
        assert level == 4
        assert trend == "worsening_trend"

    def test_high_risk_range(self):
        level, trend = score_to_level(Decimal("75"), worsening=False, has_history=True)
        assert level == 4
        assert trend == "elevated"

    def test_critical_range(self):
        level, trend = score_to_level(Decimal("90"), worsening=False, has_history=True)
        assert level == 5
        assert trend == "critical"

    def test_boundary_at_100(self):
        level, _ = score_to_level(Decimal("100"), worsening=False, has_history=True)
        assert level == 5

    def test_boundary_at_0(self):
        level, trend = score_to_level(Decimal("0"), worsening=False, has_history=False)
        assert level == 1
        assert trend == "stable_or_improving"


# ---------------------------------------------------------------------------
# _build_explanation_ar
# ---------------------------------------------------------------------------
class TestBuildExplanationAr:
    BASE_FACTORS = {
        "dimension_scores": {
            "anxiety": 2.0,
            "stress": 2.0,
            "sadness": 2.0,
            "burnout": 2.0,
            "sleep_quality": 8.0,
            "adherence": 8.0,
        },
        "trend": "stable",
    }

    def test_crisis_overrides_everything(self):
        explanation = _build_explanation_ar(5, self.BASE_FACTORS, crisis_detected=True)
        assert "مختص" in explanation
        assert "لست وحدك" in explanation

    def test_stable_low_scores_no_concern_message(self):
        explanation = _build_explanation_ar(1, self.BASE_FACTORS, crisis_detected=False)
        assert "لم تظهر مؤشرات قلق واضحة" in explanation
        assert "مستوى 1" in explanation

    def test_high_anxiety_is_mentioned(self):
        factors = {
            **self.BASE_FACTORS,
            "dimension_scores": {**self.BASE_FACTORS["dimension_scores"], "anxiety": 7.0},
        }
        explanation = _build_explanation_ar(3, factors, crisis_detected=False)
        assert "ارتفاع مستوى القلق" in explanation

    def test_poor_sleep_is_mentioned(self):
        factors = {
            **self.BASE_FACTORS,
            "dimension_scores": {**self.BASE_FACTORS["dimension_scores"], "sleep_quality": 3.0},
        }
        explanation = _build_explanation_ar(2, factors, crisis_detected=False)
        assert "ضعف جودة النوم" in explanation

    def test_poor_adherence_is_mentioned(self):
        factors = {
            **self.BASE_FACTORS,
            "dimension_scores": {**self.BASE_FACTORS["dimension_scores"], "adherence": 3.0},
        }
        explanation = _build_explanation_ar(3, factors, crisis_detected=False)
        assert "ضعف الالتزام بالعلاج" in explanation

    def test_worsening_trend_is_mentioned(self):
        factors = {
            **self.BASE_FACTORS,
            "dimension_scores": {**self.BASE_FACTORS["dimension_scores"], "anxiety": 7.0},
            "trend": "worsening_trend",
        }
        explanation = _build_explanation_ar(4, factors, crisis_detected=False)
        assert "استمرار هذا النمط" in explanation

    def test_all_risk_levels_produce_valid_arabic_text(self):
        for level in range(1, 6):
            explanation = _build_explanation_ar(level, self.BASE_FACTORS, crisis_detected=False)
            assert f"مستوى {level}" in explanation
            assert len(explanation) > 10
