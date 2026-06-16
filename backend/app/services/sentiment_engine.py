"""
Sentiment Analysis Engine - Step 3.

Implements the "Sentiment Analysis" component of the Hybrid AI Architecture
described in Step 1 (Section 7 / Section 9):

    "Using Python, Hugging Face Transformers, Arabic NLP Models
     To identify: Anxiety, Sadness, Stress, Frustration, Burnout, Positive emotions"

Design:
- A Hugging Face Arabic sentiment-analysis pipeline (if available/enabled) provides
  a *polarity* signal (positive / negative / neutral) with a confidence score.
- A curated Arabic emotion lexicon determines the specific *emotion category*
  (anxiety / stress / sadness / burnout / frustration) when the polarity is negative.
- This hybrid combination satisfies the project requirement of identifying
  specific emotions (not just generic positive/negative sentiment), while
  keeping the system fully functional ("practical for a Bachelor's project")
  even when the heavier transformer model is not downloaded/available -
  in that case the engine transparently falls back to lexicon-only analysis.

The returned `sentiment_label` is one of:
    anxiety | stress | sadness | burnout | frustration | positive | neutral
and is persisted on `InterviewAnswer.sentiment_label` / `sentiment_score`.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Optional

from app.core.config import settings

# ---------------------------------------------------------------------------
# Arabic emotion lexicon
# ---------------------------------------------------------------------------
# Each entry is a list of Arabic words/phrases (and common dialectal variants)
# strongly associated with the given emotion category. Order matters when a
# text matches multiple categories: the category with the highest hit count
# wins; ties are broken by the order below.
EMOTION_LEXICON: dict[str, list[str]] = {
    "anxiety": [
        "قلق", "قلقة", "قلقان", "خايف", "خايفة", "خوف", "متوتر", "متوترة",
        "مرعوب", "رعب", "وسواس", "هلع", "متخوف", "مرتعب", "خوفي",
    ],
    "stress": [
        "ضغط", "ضغوط", "متضايق", "ضايق", "ضايقة", "مش قادر أتحمل", "عصبية",
        "عصبي", "متعصب", "زهقت", "زهقان", "تحت ضغط", "مضغوط",
    ],
    "sadness": [
        "حزين", "حزينة", "حزن", "زعلان", "زعلانة", "مكتئب", "مكتئبة", "اكتئاب",
        "بكيت", "دموع", "يأس", "يائس", "حسرة", "مهموم", "مهمومة",
    ],
    "burnout": [
        "مرهق", "مرهقة", "إرهاق", "تعبت من", "ما عندي طاقة", "مش قادر أكمل",
        "استنزاف", "خلصت طاقتي", "تعب نفسي", "تعب شديد", "مستنزف", "مستنزفة",
    ],
    "frustration": [
        "محبط", "محبطة", "إحباط", "زهقت من", "ملل", "ملّيت", "تعبت من المحاولة",
        "مافي فايدة", "ما في فايدة", "بدون فايدة", "فاشل", "فشلت",
    ],
    "positive": [
        "بخير", "تمام", "ممتاز", "سعيد", "سعيدة", "مبسوط", "مبسوطة", "متحسن",
        "متحسنة", "أفضل", "الحمدلله", "الحمد لله", "مرتاح", "مرتاحة", "متفائل",
        "متفائلة", "نشيط", "نشيطة",
    ],
}

# Categories considered when a HF model reports a NEGATIVE polarity.
NEGATIVE_EMOTION_CATEGORIES = ["anxiety", "stress", "sadness", "burnout", "frustration"]


@dataclass
class SentimentResult:
    label: str  # anxiety | stress | sadness | burnout | frustration | positive | neutral
    score: float  # 0.0 - 1.0 confidence
    polarity: str  # positive | negative | neutral (raw polarity signal)
    source: str  # "hf_model+lexicon" | "lexicon_only"


class SentimentEngine:
    """
    Lazily loads the Hugging Face Arabic sentiment pipeline (if
    `settings.ENABLE_HF_SENTIMENT` is true). If the library or model is
    unavailable for any reason (not installed, no network access, etc.),
    the engine transparently degrades to lexicon-only analysis so the
    platform remains fully operational.
    """

    def __init__(self) -> None:
        self._pipeline = None
        self._pipeline_load_attempted = False

    # ------------------------------------------------------------------
    def _get_pipeline(self):
        if not settings.ENABLE_HF_SENTIMENT:
            return None

        if self._pipeline_load_attempted:
            return self._pipeline

        self._pipeline_load_attempted = True
        try:
            from transformers import pipeline  # type: ignore

            self._pipeline = pipeline("sentiment-analysis", model=settings.HF_SENTIMENT_MODEL)
        except Exception:
            # Model/library unavailable - degrade gracefully to lexicon-only mode.
            self._pipeline = None

        return self._pipeline

    # ------------------------------------------------------------------
    def _lexicon_scores(self, text: str) -> dict[str, int]:
        normalized = re.sub(r"[^\u0600-\u06FF\s]", " ", text)  # keep Arabic letters + spaces
        scores: dict[str, int] = {}
        for category, keywords in EMOTION_LEXICON.items():
            hits = sum(1 for kw in keywords if kw in normalized)
            if hits:
                scores[category] = hits
        return scores

    def _lexicon_polarity(self, lexicon_scores: dict[str, int]) -> tuple[str, float]:
        if not lexicon_scores:
            return "neutral", 0.0

        positive_hits = lexicon_scores.get("positive", 0)
        negative_hits = sum(v for k, v in lexicon_scores.items() if k in NEGATIVE_EMOTION_CATEGORIES)

        if negative_hits > positive_hits:
            return "negative", min(0.5 + 0.1 * negative_hits, 0.95)
        if positive_hits > negative_hits:
            return "positive", min(0.5 + 0.1 * positive_hits, 0.95)
        return "neutral", 0.3

    # ------------------------------------------------------------------
    def analyze(self, text_ar: Optional[str]) -> SentimentResult:
        if not text_ar or not text_ar.strip():
            return SentimentResult(label="neutral", score=0.0, polarity="neutral", source="lexicon_only")

        lexicon_scores = self._lexicon_scores(text_ar)

        pipeline_ = self._get_pipeline()
        if pipeline_ is not None:
            try:
                result = pipeline_(text_ar[:512])[0]
                polarity = str(result.get("label", "neutral")).lower()
                hf_score = float(result.get("score", 0.5))
                # Normalize common label variants
                if polarity in ("pos", "positive", "label_2"):
                    polarity = "positive"
                elif polarity in ("neg", "negative", "label_0"):
                    polarity = "negative"
                else:
                    polarity = "neutral"
                source = "hf_model+lexicon"
            except Exception:
                polarity, hf_score = self._lexicon_polarity(lexicon_scores)
                source = "lexicon_only"
        else:
            polarity, hf_score = self._lexicon_polarity(lexicon_scores)
            source = "lexicon_only"

        # Determine specific emotion category using the lexicon when polarity is negative.
        if polarity == "negative":
            negative_candidates = {
                k: v for k, v in lexicon_scores.items() if k in NEGATIVE_EMOTION_CATEGORIES
            }
            if negative_candidates:
                label = max(negative_candidates, key=negative_candidates.get)
            else:
                # HF flagged negative sentiment but lexicon found no specific category -
                # default to "stress" as the most general negative-emotion bucket.
                label = "stress"
            return SentimentResult(label=label, score=hf_score, polarity=polarity, source=source)

        if polarity == "positive":
            return SentimentResult(label="positive", score=hf_score, polarity=polarity, source=source)

        # Neutral polarity from the model - still check lexicon for strong emotion words,
        # since short Arabic replies are often misclassified as neutral by generic models.
        negative_candidates = {k: v for k, v in lexicon_scores.items() if k in NEGATIVE_EMOTION_CATEGORIES}
        if negative_candidates:
            label = max(negative_candidates, key=negative_candidates.get)
            return SentimentResult(label=label, score=0.6, polarity="negative", source=source)

        if lexicon_scores.get("positive"):
            return SentimentResult(label="positive", score=0.6, polarity="positive", source=source)

        return SentimentResult(label="neutral", score=hf_score, polarity="neutral", source=source)


# Module-level singleton (model loaded lazily on first use, if enabled).
sentiment_engine = SentimentEngine()
