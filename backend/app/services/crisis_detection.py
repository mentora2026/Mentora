"""
Crisis Language Detection - Step 3.

Implements the safeguard described in Step 1 Section 7.5:

    "Detection of explicit crisis/self-harm language always forces at
     minimum Level 5, regardless of composite score, and immediately
     triggers an admin notification (`risk_alert_admin`) and a
     recommendation in category `professional_help`."

This is a deliberately simple, transparent, high-recall keyword check -
NOT an attempt at clinical diagnosis. Its only job is to make sure that
any sign of self-harm/suicidal language is never "averaged away" by the
normal scoring pipeline and is immediately escalated to a human.
"""

from __future__ import annotations

import re

CRISIS_KEYWORDS_AR: list[str] = [
    "أريد أن أموت",
    "أريد الموت",
    "نفسي أموت",
    "ما أبغى أعيش",
    "لا أريد أن أعيش",
    "تمنيت الموت",
    "أفكر في الانتحار",
    "أفكر بالانتحار",
    "أنتحر",
    "أؤذي نفسي",
    "إيذاء نفسي",
    "أجرح نفسي",
    "ما فيه فايدة من حياتي",
    "حياتي ما لها معنى",
    "أفضل أموت",
    "خلصت من حياتي",
]


def contains_crisis_language(text_ar: str | None) -> bool:
    """
    Returns True if the given Arabic text contains explicit
    self-harm / suicidal-ideation language.
    """
    if not text_ar:
        return False

    normalized = re.sub(r"\s+", " ", text_ar.strip())
    return any(keyword in normalized for keyword in CRISIS_KEYWORDS_AR)
