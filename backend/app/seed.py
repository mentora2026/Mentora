"""
Seed script for the Adaptive Psychological Monitoring Platform.

Populates:
- chronic_conditions (master list + Disease Knowledge Layer config)
- interview_questions (generic + disease-specific samples)
- recommendations (sample catalog entries per category/risk level)
- A default admin user

Run with:  python -m app.seed
"""

from app.core.database import SessionLocal, engine
from app.core.security import hash_password
from app.models import (
    Base,
    ChronicCondition,
    InterviewQuestion,
    Recommendation,
    User,
)
from app.models.enums import QuestionCategory, QuestionType, RecommendationCategory, UserRole

CONDITIONS = [
    {
        "code": "diabetes",
        "name_en": "Diabetes",
        "name_ar": "مرض السكري",
        "description_ar": "مرض مزمن يؤثر على مستوى السكر في الدم ويتطلب إدارة مستمرة لنمط الحياة والعلاج.",
        "knowledge_config_json": {
            "disease_code": "diabetes",
            "priority_categories": ["adherence", "burnout", "stress", "anxiety", "sleep"],
            "psychological_burdens": [
                "treatment_fatigue",
                "burnout",
                "fear_of_complications",
                "lifestyle_restriction_frustration",
            ],
            "risk_indicators": [
                "skipped_medication_mentions",
                "repeated_negative_sentiment_on_adherence",
            ],
            "emotional_patterns": {
                "burnout": {"follow_up_category": "adherence"},
                "anxiety": {"follow_up_category": "burnout"},
            },
        },
    },
    {
        "code": "cancer",
        "name_en": "Cancer",
        "name_ar": "مرض السرطان",
        "description_ar": "مرض مزمن يتطلب علاجاً طويل الأمد ويصاحبه أعباء نفسية كبيرة.",
        "knowledge_config_json": {
            "disease_code": "cancer",
            "priority_categories": ["anxiety", "sadness", "adaptation"],
            "psychological_burdens": ["fear_of_recurrence", "anxiety", "uncertainty", "emotional_distress"],
            "risk_indicators": ["recurrence_fear_language", "expressions_of_hopelessness"],
            "emotional_patterns": {
                "anxiety": {"follow_up_category": "sadness"},
                "sadness": {"follow_up_category": "adaptation"},
            },
        },
    },
    {
        "code": "kidney_failure",
        "name_en": "Kidney Failure",
        "name_ar": "الفشل الكلوي",
        "description_ar": "حالة مزمنة قد تتطلب جلسات غسيل كلوي منتظمة وتؤثر على الطاقة والحياة الاجتماعية.",
        "knowledge_config_json": {
            "disease_code": "kidney_failure",
            "priority_categories": ["social_isolation", "burnout", "sleep"],
            "psychological_burdens": ["isolation", "exhaustion", "reduced_motivation", "dialysis_burden"],
            "risk_indicators": ["social_withdrawal", "dialysis_exhaustion_language"],
            "emotional_patterns": {
                "burnout": {"follow_up_category": "social_isolation"},
                "sadness": {"follow_up_category": "burnout"},
            },
        },
    },
    {
        "code": "heart_disease",
        "name_en": "Heart Disease",
        "name_ar": "أمراض القلب",
        "description_ar": "أمراض مزمنة في القلب قد تصاحبها مخاوف من تكرار النوبات وتوتر مستمر.",
        "knowledge_config_json": {
            "disease_code": "heart_disease",
            "priority_categories": ["anxiety", "stress"],
            "psychological_burdens": ["fear_of_relapse", "health_anxiety", "stress"],
            "risk_indicators": ["catastrophizing_symptoms", "activity_avoidance"],
            "emotional_patterns": {
                "anxiety": {"follow_up_category": "stress"},
            },
        },
    },
    {
        "code": "hypertension",
        "name_en": "Hypertension",
        "name_ar": "ارتفاع ضغط الدم",
        "description_ar": "حالة مزمنة شائعة ترتبط غالباً بالتوتر والالتزام بالعلاج.",
        "knowledge_config_json": {
            "disease_code": "hypertension",
            "priority_categories": ["stress", "adherence"],
            "psychological_burdens": ["stress_related_concerns", "adherence_concerns"],
            "risk_indicators": ["stress_triggered_symptoms"],
            "emotional_patterns": {
                "stress": {"follow_up_category": "adherence"},
            },
        },
    },
    {
        "code": "asthma",
        "name_en": "Asthma",
        "name_ar": "الربو",
        "description_ar": "حالة تنفسية مزمنة قد تترافق مع القلق من نوبات الربو وتقييد النشاط.",
        "knowledge_config_json": {
            "disease_code": "asthma",
            "priority_categories": ["anxiety", "stress"],
            "psychological_burdens": ["attack_anxiety", "activity_limitation"],
            "risk_indicators": ["avoidance_behavior", "panic_language"],
            "emotional_patterns": {
                "anxiety": {"follow_up_category": "stress"},
            },
        },
    },
]

GENERIC_QUESTIONS = [
    (QuestionCategory.general, "كيف تشعر بشكل عام اليوم؟", QuestionType.open_text, 1),
    (QuestionCategory.sleep, "كيف تقيّم جودة نومك خلال الأيام الماضية؟ (1 = سيئة جداً، 5 = ممتازة)", QuestionType.scale_1_5, 1),
    (QuestionCategory.adherence, "كيف تقيّم التزامك بأخذ العلاج أو الإجراءات الموصى بها هذا الأسبوع؟ (1 = ضعيف جداً، 5 = ممتاز)", QuestionType.scale_1_5, 1),
    (QuestionCategory.anxiety, "هل شعرت بالقلق أو التوتر بشأن صحتك مؤخراً؟ حدثني أكثر عن ذلك.", QuestionType.open_text, 1),
    (QuestionCategory.stress, "ما هي أكبر مصادر الضغط النفسي في حياتك هذه الأيام؟", QuestionType.open_text, 1),
    (QuestionCategory.sadness, "هل لاحظت تغيراً في مزاجك أو شعرت بالحزن بشكل متكرر مؤخراً؟", QuestionType.open_text, 1),
    (QuestionCategory.burnout, "هل تشعر بالإرهاق أو التعب من التعامل المستمر مع حالتك الصحية؟", QuestionType.open_text, 1),
    (QuestionCategory.social_isolation, "كيف تصف علاقتك بالأشخاص المقربين منك هذه الفترة؟ هل تشعر بالعزلة؟", QuestionType.open_text, 1),
    (QuestionCategory.adaptation, "كيف تتعامل مع التغييرات التي طرأت على حياتك بسبب حالتك الصحية؟", QuestionType.open_text, 2),
]

DISEASE_SPECIFIC_QUESTIONS = {
    "diabetes": [
        (QuestionCategory.burnout, "هل تشعر بالتعب من المتابعة المستمرة لمستوى السكر والنظام الغذائي؟", QuestionType.open_text, 2),
        (QuestionCategory.anxiety, "هل تشغلك أفكار حول مضاعفات مرض السكري على المدى الطويل؟", QuestionType.open_text, 2),
    ],
    "cancer": [
        (QuestionCategory.anxiety, "هل تشعر بالقلق من احتمال عودة المرض؟ كيف تتعامل مع هذا الشعور؟", QuestionType.open_text, 2),
        (QuestionCategory.sadness, "كيف تتعامل مع الشعور بعدم اليقين بشأن المستقبل؟", QuestionType.open_text, 2),
    ],
    "kidney_failure": [
        (QuestionCategory.social_isolation, "هل أثرت جلسات الغسيل الكلوي على قدرتك على التواصل مع الآخرين؟", QuestionType.open_text, 2),
        (QuestionCategory.burnout, "كيف تصف مستوى طاقتك في الأيام التي تخضع فيها لجلسات العلاج؟", QuestionType.open_text, 2),
    ],
    "heart_disease": [
        (QuestionCategory.anxiety, "هل تشعر بالقلق من ممارسة الأنشطة اليومية بسبب مخاوف متعلقة بقلبك؟", QuestionType.open_text, 2),
    ],
    "hypertension": [
        (QuestionCategory.stress, "هل تلاحظ أن التوتر اليومي يؤثر على شعورك بصحتك العامة؟", QuestionType.open_text, 2),
    ],
    "asthma": [
        (QuestionCategory.anxiety, "هل تشعر بالقلق من احتمال حدوث نوبة ربو في أماكن أو أوقات معينة؟", QuestionType.open_text, 2),
    ],
}

RECOMMENDATIONS = [
    {
        "category": RecommendationCategory.motivational,
        "applicable_risk_levels": [1, 2],
        "title_ar": "أنت تقوم بعمل رائع",
        "content_ar": "استمر في متابعة حالتك الصحية والنفسية بهذا الشكل الإيجابي. خطواتك الصغيرة اليومية تصنع فرقاً كبيراً على المدى الطويل.",
    },
    {
        "category": RecommendationCategory.educational,
        "applicable_risk_levels": [1, 2, 3],
        "title_ar": "فهم العلاقة بين الحالة النفسية والمرض المزمن",
        "content_ar": "من الطبيعي أن تتأثر حالتك النفسية بمرضك المزمن. التعرف على هذه العلاقة هو خطوة أولى مهمة للتعامل معها بشكل صحي.",
    },
    {
        "category": RecommendationCategory.sleep_tip,
        "applicable_risk_levels": [2, 3],
        "title_ar": "نصائح لتحسين جودة النوم",
        "content_ar": "حاول الالتزام بوقت ثابت للنوم والاستيقاظ، وتجنب استخدام الهاتف قبل النوم بساعة، وخصص وقتاً للاسترخاء قبل النوم.",
    },
    {
        "category": RecommendationCategory.breathing_exercise,
        "applicable_risk_levels": [2, 3, 4],
        "title_ar": "تمرين التنفس العميق",
        "content_ar": "خذ نفساً عميقاً من الأنف لمدة 4 ثوانٍ، احبسه لمدة 4 ثوانٍ، ثم أخرجه ببطء من الفم لمدة 6 ثوانٍ. كرر هذا التمرين 5 مرات عند الشعور بالتوتر.",
    },
    {
        "category": RecommendationCategory.stress_management,
        "applicable_risk_levels": [3, 4],
        "title_ar": "تقنيات لتقليل التوتر اليومي",
        "content_ar": "خصص 10 دقائق يومياً لنشاط يساعدك على الاسترخاء كالمشي الهادئ أو الاستماع لموسيقى مهدئة، وحاول تدوين أفكارك المسببة للتوتر لتفهمها بشكل أوضح.",
    },
    {
        "category": RecommendationCategory.relaxation,
        "applicable_risk_levels": [2, 3, 4],
        "title_ar": "تمرين الاسترخاء التدريجي للعضلات",
        "content_ar": "ابدأ بشد عضلات قدميك لمدة 5 ثوانٍ ثم أرخها، وانتقل تدريجياً إلى الأعلى حتى تصل إلى عضلات الوجه. هذا التمرين يساعد على تخفيف التوتر الجسدي والنفسي.",
    },
    {
        "category": RecommendationCategory.professional_help,
        "applicable_risk_levels": [4, 5],
        "title_ar": "قد يكون من المفيد التحدث مع مختص",
        "content_ar": "بناءً على ما شاركته معنا، قد يكون من المفيد التحدث مع مختص في الصحة النفسية أو طبيبك المعالج للحصول على دعم إضافي. هذا التطبيق لا يقدم تشخيصاً طبياً، وطلب المساعدة المتخصصة خطوة إيجابية ومهمة.",
    },
]


def seed():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        # Chronic conditions
        condition_objs: dict[str, ChronicCondition] = {}
        for c in CONDITIONS:
            existing = db.query(ChronicCondition).filter(ChronicCondition.code == c["code"]).first()
            if existing:
                # Refresh the Disease Knowledge Layer config in case it was
                # extended (e.g., new emotional_patterns added in Step 3).
                existing.knowledge_config_json = c["knowledge_config_json"]
                existing.description_ar = c["description_ar"]
                db.add(existing)
                condition_objs[c["code"]] = existing
                continue
            obj = ChronicCondition(**c)
            db.add(obj)
            db.flush()
            condition_objs[c["code"]] = obj

        # Generic interview questions
        if db.query(InterviewQuestion).filter(InterviewQuestion.chronic_condition_id.is_(None)).count() == 0:
            for category, text_ar, q_type, depth in GENERIC_QUESTIONS:
                db.add(
                    InterviewQuestion(
                        chronic_condition_id=None,
                        category=category,
                        question_text_ar=text_ar,
                        question_type=q_type,
                        difficulty_depth=depth,
                    )
                )

        # Disease-specific interview questions
        for code, questions in DISEASE_SPECIFIC_QUESTIONS.items():
            condition = condition_objs[code]
            existing_count = (
                db.query(InterviewQuestion).filter(InterviewQuestion.chronic_condition_id == condition.id).count()
            )
            if existing_count > 0:
                continue
            for category, text_ar, q_type, depth in questions:
                db.add(
                    InterviewQuestion(
                        chronic_condition_id=condition.id,
                        category=category,
                        question_text_ar=text_ar,
                        question_type=q_type,
                        difficulty_depth=depth,
                    )
                )

        # Recommendations
        if db.query(Recommendation).count() == 0:
            for r in RECOMMENDATIONS:
                db.add(Recommendation(**r, chronic_condition_id=None, is_active=True))

        # Default admin user
        if db.query(User).filter(User.role == UserRole.admin).count() == 0:
            db.add(
                User(
                    email="admin@platform.example",
                    password_hash=hash_password("ChangeMe123!"),
                    full_name="مسؤول النظام",
                    role=UserRole.admin,
                )
            )

        db.commit()
        print("Seed data inserted successfully.")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
