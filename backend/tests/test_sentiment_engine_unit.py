"""
Sentiment Analysis Engine evaluation tests (Step 1 Section 7 / 9: "Sentiment
Analysis ... To identify: Anxiety, Sadness, Stress, Frustration, Burnout,
Positive emotions"). These tests require no database connection and run in
lexicon-only mode (the default, `ENABLE_HF_SENTIMENT=false`).
"""

import pytest

from app.services.sentiment_engine import SentimentEngine, sentiment_engine


# ---------------------------------------------------------------------------
# Per-emotion classification accuracy (lexicon mode)
# ---------------------------------------------------------------------------
class TestEmotionClassification:
    @pytest.mark.parametrize(
        "text,expected_label",
        [
            ("أشعر بقلق شديد وخوف من المستقبل", "anxiety"),
            ("أنا متوتر جداً ومضغوط بسبب كل هذه الأمور", "stress"),
            ("أشعر بحزن شديد ودموعي لا تتوقف", "sadness"),
            ("أنا مرهق جداً ومستنزف، ما عندي طاقة أكمل", "burnout"),
            ("محبط جداً، حسيت إن مافي فايدة من المحاولة", "frustration"),
            ("الحمدلله أنا بخير ومتحسن هذه الأيام", "positive"),
        ],
    )
    def test_emotion_keywords_classified_correctly(self, text, expected_label):
        result = sentiment_engine.analyze(text)
        assert result.label == expected_label
        assert result.polarity in ("negative", "positive")
        assert 0.0 <= result.score <= 1.0

    def test_neutral_text_with_no_keywords(self):
        result = sentiment_engine.analyze("ذهبت إلى السوق اليوم وعدت إلى المنزل")
        assert result.label == "neutral"
        assert result.polarity == "neutral"

    def test_empty_string(self):
        result = sentiment_engine.analyze("")
        assert result.label == "neutral"
        assert result.score == 0.0
        assert result.source == "lexicon_only"

    def test_whitespace_only(self):
        result = sentiment_engine.analyze("   ")
        assert result.label == "neutral"

    def test_none_input(self):
        result = sentiment_engine.analyze(None)
        assert result.label == "neutral"
        assert result.score == 0.0


# ---------------------------------------------------------------------------
# Mixed / ambiguous input handling
# ---------------------------------------------------------------------------
class TestMixedSentiment:
    def test_more_negative_keywords_wins(self):
        text = "أنا بخير لكن أشعر بقلق وتوتر شديد من نتائج الفحوصات"
        result = sentiment_engine.analyze(text)
        assert result.label in ("anxiety", "stress")
        assert result.polarity == "negative"

    def test_more_positive_keywords_wins(self):
        text = "اليوم كان متعباً قليلاً لكنني الحمدلله بخير ومتحسن ومرتاح"
        result = sentiment_engine.analyze(text)
        assert result.label == "positive"

    def test_long_text_handled_safely(self):
        text = "أشعر بقلق شديد. " * 100
        result = sentiment_engine.analyze(text)
        assert result.label == "anxiety"


# ---------------------------------------------------------------------------
# Graceful degradation when HF model is unavailable / disabled
# ---------------------------------------------------------------------------
class TestGracefulDegradation:
    def test_disabled_hf_uses_lexicon_only(self):
        engine = SentimentEngine()
        # ENABLE_HF_SENTIMENT defaults to False, so _get_pipeline should return None.
        assert engine._get_pipeline() is None

        result = engine.analyze("أشعر بحزن شديد")
        assert result.source == "lexicon_only"
        assert result.label == "sadness"

    def test_disabled_hf_short_circuits_without_attempting_load(self):
        engine = SentimentEngine()
        # When ENABLE_HF_SENTIMENT is False, _get_pipeline returns None
        # immediately without ever attempting to import/load the model.
        assert engine._get_pipeline() is None
        assert engine._pipeline_load_attempted is False
        assert engine._get_pipeline() is None
