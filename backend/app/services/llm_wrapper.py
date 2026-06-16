"""
LLM Wrapper - Step 3.

Implements the "LLM Usage" component from Step 1 (Section 7 / 9.2):

    "Use LLMs ONLY when necessary for:
       - Question rephrasing
       - Arabic language generation
       - Session summarization
       - Recommendation explanation
     Avoid making the entire system dependent on LLMs."

Governance (Step 1 Section 9.2):
- All output must be in Arabic.
- Supportive, non-judgmental tone.
- No medical diagnosis, no medication advice, no definitive medical claims.

Implementation notes:
- When `settings.ENABLE_LLM` is False (default) or the API call fails for
  any reason (no key, no network, etc.), every function falls back to a
  deterministic, template-based Arabic output. This keeps the platform
  fully functional without an LLM dependency, per Step 1's "hybrid /
  practical" requirement, while still satisfying every call site's contract.
"""

from __future__ import annotations

from typing import Optional

import httpx

from app.core.config import settings

SYSTEM_PROMPT_AR = (
    "أنت مساعد لغوي يعمل ضمن منصة دعم نفسي لمرضى الأمراض المزمنة. "
    "مهمتك فقط هي إعادة صياغة النصوص أو تلخيصها أو شرحها باللغة العربية الفصحى أو "
    "العربية اليومية المفهومة، بأسلوب داعم ولطيف وغير حكمي. "
    "ممنوع تماماً تقديم أي تشخيص طبي أو نفسي، أو وصف أدوية، أو إصدار أحكام طبية قاطعة. "
    "أعد فقط النص المطلوب دون أي مقدمات أو تعليقات إضافية."
)


def _call_llm(user_prompt: str, max_tokens: int = 400) -> Optional[str]:
    """
    Calls the configured LLM provider. Returns None on any failure so
    callers can fall back to their template-based default.
    """
    if not settings.ENABLE_LLM or not settings.LLM_API_KEY:
        return None

    if settings.LLM_PROVIDER != "anthropic":
        return None

    try:
        response = httpx.post(
            "https://api.anthropic.com/v1/messages",
            headers={
                "x-api-key": settings.LLM_API_KEY,
                "anthropic-version": "2023-06-01",
                "content-type": "application/json",
            },
            json={
                "model": settings.LLM_MODEL,
                "max_tokens": max_tokens,
                "system": SYSTEM_PROMPT_AR,
                "messages": [{"role": "user", "content": user_prompt}],
            },
            timeout=15.0,
        )
        response.raise_for_status()
        data = response.json()
        text_blocks = [b["text"] for b in data.get("content", []) if b.get("type") == "text"]
        text = "\n".join(text_blocks).strip()
        return text or None
    except Exception:
        return None


# ---------------------------------------------------------------------------
# Question rephrasing
# ---------------------------------------------------------------------------
def rephrase_question_ar(base_question_ar: str, context_hint: Optional[str] = None) -> str:
    """
    Rephrases a template question in natural Arabic, optionally personalizing
    it with `context_hint` (e.g., a reference to the patient's previous answer).
    The *intent/category* of the question is decided by the rule-based
    Question Selector - this function only affects wording.
    """
    prompt = (
        "أعد صياغة السؤال التالي بأسلوب طبيعي وودود باللغة العربية، "
        "مع الحفاظ على المعنى والغرض الأصلي للسؤال تماماً، وبدون تغيير نوع السؤال "
        "(إن كان يطلب إجابة نصية أو تقييم من 1 إلى 5 فحافظ على ذلك).\n\n"
    )
    if context_hint:
        prompt += f"سياق إضافي من إجابة سابقة للمريض (للاستئناس فقط): {context_hint}\n\n"
    prompt += f"السؤال الأصلي: {base_question_ar}"

    rephrased = _call_llm(prompt, max_tokens=200)
    return rephrased or base_question_ar


# ---------------------------------------------------------------------------
# Session summarization
# ---------------------------------------------------------------------------
def generate_session_summary_ar(qa_pairs: list[tuple[str, str]], dominant_emotions: list[str]) -> str:
    """
    Generates a short Arabic summary of the completed interview session.

    qa_pairs: list of (question_text_ar, answer_text_ar)
    dominant_emotions: emotion labels that appeared most frequently this session
                        (e.g., ["anxiety", "burnout"])
    """
    fallback = _template_session_summary_ar(dominant_emotions)

    if not qa_pairs:
        return fallback

    qa_text = "\n".join(f"- س: {q}\n  ج: {a}" for q, a in qa_pairs if a)
    prompt = (
        "لخّص جلسة المحادثة النفسية التالية في 2-3 جمل باللغة العربية، بأسلوب داعم وودود، "
        "بدون ذكر أي تشخيص طبي أو نفسي، وبدون استخدام عبارات تنذر بالخطر إذا لم تكن واردة بوضوح:\n\n"
        f"{qa_text}"
    )
    summary = _call_llm(prompt, max_tokens=300)
    return summary or fallback


def _template_session_summary_ar(dominant_emotions: list[str]) -> str:
    emotion_phrases = {
        "anxiety": "بعض مشاعر القلق",
        "stress": "مستوى من التوتر",
        "sadness": "بعض مشاعر الحزن",
        "burnout": "علامات إرهاق نفسي",
        "frustration": "بعض مشاعر الإحباط",
        "positive": "مشاعر إيجابية بشكل عام",
    }

    relevant = [emotion_phrases[e] for e in dominant_emotions if e in emotion_phrases]
    if relevant:
        emotions_text = "، ".join(relevant)
        return (
            f"تم استكمال الجلسة بنجاح. لاحظنا خلال هذه الجلسة {emotions_text}. "
            "تم تسجيل إجاباتك وسنقدم لك توصيات مناسبة بناءً عليها."
        )

    return "تم استكمال الجلسة بنجاح وتسجيل إجاباتك. لم تظهر مؤشرات قلق واضحة خلال هذه الجلسة."


# ---------------------------------------------------------------------------
# Risk explanation generation
# ---------------------------------------------------------------------------
def generate_risk_explanation_ar(risk_level: int, factors: dict, template_explanation_ar: str) -> str:
    """
    Optionally enhances the rule-based Arabic explanation (already generated
    by the Risk Engine) into more natural phrasing. The *content* (risk level
    and contributing factors) is always determined by the rule-based engine -
    the LLM only affects wording/fluency.
    """
    prompt = (
        "أعد صياغة الشرح التالي الموجه لمريض حول نتيجة تقييم نفسي، بحيث يكون أكثر "
        "دفئاً وتعاطفاً، مع الحفاظ التام على المعلومات والمستوى المذكور دون إضافة "
        "أي معلومة جديدة أو تشخيص طبي:\n\n"
        f"{template_explanation_ar}"
    )
    enhanced = _call_llm(prompt, max_tokens=250)
    return enhanced or template_explanation_ar


# ---------------------------------------------------------------------------
# Recommendation explanation
# ---------------------------------------------------------------------------
def explain_recommendation_ar(recommendation_title_ar: str, recommendation_content_ar: str, risk_level: int) -> str:
    """
    Generates a brief Arabic note explaining *why* a recommendation was
    suggested, to be shown alongside it. Falls back to a generic template.
    """
    fallback = "تم اختيار هذه التوصية بناءً على إجاباتك في آخر جلسة محادثة."

    prompt = (
        "اكتب جملة واحدة باللغة العربية تشرح للمريض بشكل لطيف ومختصر سبب تلقيه "
        f"التوصية التالية، بدون ذكر أرقام أو مستويات خطر تقنية:\n\n"
        f"عنوان التوصية: {recommendation_title_ar}\n"
        f"محتوى التوصية: {recommendation_content_ar}"
    )
    explanation = _call_llm(prompt, max_tokens=100)
    return explanation or fallback
