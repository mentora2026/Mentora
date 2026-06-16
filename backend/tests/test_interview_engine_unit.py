"""
Unit tests for the Adaptive Interview Engine's pure helper functions
(Step 1 Section 5 / 6.4). These tests require no database connection.
"""

from app.core.config import settings
from app.services.interview_engine import (
    DEFAULT_CATEGORY_ORDER,
    InterviewEngine,
    build_priority_category_order,
    top_emotions,
)


# ---------------------------------------------------------------------------
# build_priority_category_order
# ---------------------------------------------------------------------------
class TestBuildPriorityCategoryOrder:
    def test_no_conditions_returns_default_order(self):
        result = build_priority_category_order([])
        assert result == [c.value for c in DEFAULT_CATEGORY_ORDER]

    def test_single_condition_priorities_come_first(self):
        diabetes_config = {"priority_categories": ["adherence", "burnout", "stress"]}
        result = build_priority_category_order([diabetes_config])

        assert result[:3] == ["adherence", "burnout", "stress"]
        assert "anxiety" in result
        assert result.count("adherence") == 1

    def test_multiple_conditions_merge_without_duplicates(self):
        diabetes_config = {"priority_categories": ["adherence", "burnout"]}
        cancer_config = {"priority_categories": ["anxiety", "sadness", "adherence"]}
        result = build_priority_category_order([diabetes_config, cancer_config])

        assert result[0] == "adherence"
        assert result[1] == "burnout"
        assert "anxiety" in result[2:4]
        assert "sadness" in result[2:4]
        assert result.count("adherence") == 1

    def test_missing_priority_categories_key(self):
        result = build_priority_category_order([{}])
        assert result == [c.value for c in DEFAULT_CATEGORY_ORDER]

    def test_all_default_categories_present_in_result(self):
        config = {"priority_categories": ["sleep"]}
        result = build_priority_category_order([config])
        for cat in DEFAULT_CATEGORY_ORDER:
            assert cat.value in result


# ---------------------------------------------------------------------------
# top_emotions
# ---------------------------------------------------------------------------
class TestTopEmotions:
    def test_empty_history(self):
        assert top_emotions([]) == []

    def test_excludes_neutral(self):
        assert top_emotions(["neutral", "neutral"]) == []

    def test_most_frequent_first(self):
        history = ["anxiety", "anxiety", "burnout", "anxiety", "stress"]
        result = top_emotions(history, limit=2)
        assert result[0] == "anxiety"
        assert "burnout" in result or "stress" in result
        assert len(result) == 2

    def test_limit_respected(self):
        history = ["anxiety", "stress", "sadness", "burnout"]
        result = top_emotions(history, limit=1)
        assert len(result) == 1

    def test_fewer_emotions_than_limit(self):
        history = ["anxiety"]
        result = top_emotions(history, limit=2)
        assert result == ["anxiety"]


# ---------------------------------------------------------------------------
# InterviewEngine._should_terminate
# ---------------------------------------------------------------------------
class TestShouldTerminate:
    def setup_method(self):
        # _should_terminate doesn't touch self.db, so a None db is safe here.
        self.engine = InterviewEngine(db=None)

    def test_below_minimum_does_not_terminate(self):
        context = {"answers_count": 1, "covered_categories": ["general"]}
        assert self.engine._should_terminate(context) is False

    def test_reaches_max_questions_terminates(self):
        context = {
            "answers_count": settings.INTERVIEW_MAX_QUESTIONS,
            "covered_categories": ["general"],
        }
        assert self.engine._should_terminate(context) is True

    def test_min_reached_and_all_categories_covered_terminates(self):
        context = {
            "answers_count": settings.INTERVIEW_MIN_QUESTIONS,
            "covered_categories": [c.value for c in DEFAULT_CATEGORY_ORDER],
        }
        assert self.engine._should_terminate(context) is True

    def test_min_reached_but_categories_not_covered_continues(self):
        context = {
            "answers_count": settings.INTERVIEW_MIN_QUESTIONS,
            "covered_categories": ["general"],
        }
        assert self.engine._should_terminate(context) is False

    def test_pending_escalation_prevents_early_termination(self):
        context = {
            "answers_count": settings.INTERVIEW_MIN_QUESTIONS,
            "covered_categories": [c.value for c in DEFAULT_CATEGORY_ORDER],
            "escalation_pending": True,
        }
        assert self.engine._should_terminate(context) is False

    def test_max_questions_overrides_pending_escalation(self):
        context = {
            "answers_count": settings.INTERVIEW_MAX_QUESTIONS,
            "covered_categories": ["general"],
            "escalation_pending": True,
        }
        assert self.engine._should_terminate(context) is True
