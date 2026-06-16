/// Centralized Arabic UI strings.
///
/// Per the project's language rule, ALL user-facing text is in Arabic.
/// Keeping strings here (rather than scattered as literals) makes the app
/// easy to review for translation consistency and to extend with full
/// `flutter_localizations` ARB-based i18n later if needed.
class AppStrings {
  AppStrings._();

  // App
  static const String appName = "منصة الدعم النفسي";

  // Auth
  static const String login = "تسجيل الدخول";
  static const String register = "إنشاء حساب";
  static const String email = "البريد الإلكتروني";
  static const String password = "كلمة المرور";
  static const String fullName = "الاسم الكامل";
  static const String phoneNumber = "رقم الهاتف (اختياري)";
  static const String confirmPassword = "تأكيد كلمة المرور";
  static const String dontHaveAccount = "ليس لديك حساب؟ سجّل الآن";
  static const String alreadyHaveAccount = "لديك حساب بالفعل؟ سجّل الدخول";
  static const String loginButton = "دخول";
  static const String registerButton = "إنشاء الحساب";
  static const String logout = "تسجيل الخروج";
  static const String passwordsDoNotMatch = "كلمتا المرور غير متطابقتين";
  static const String invalidCredentials = "البريد الإلكتروني أو كلمة المرور غير صحيحة";

  // Onboarding / Profile
  static const String profileSetupTitle = "إعداد الملف الشخصي";
  static const String chronicConditionsLabel = "الأمراض المزمنة";
  static const String addCondition = "إضافة مرض";
  static const String diseaseDuration = "منذ متى تشخصت بهذا المرض؟ (بالأشهر)";
  static const String medications = "الأدوية الحالية";
  static const String sleepHours = "متوسط ساعات النوم اليومية";
  static const String activityLevel = "مستوى النشاط البدني";
  static const String socialSupport = "مستوى الدعم الاجتماعي";
  static const String medicalBackground = "ملاحظات عن تاريخك الطبي (اختياري)";
  static const String saveProfile = "حفظ الملف الشخصي";
  static const String profileSaved = "تم حفظ الملف الشخصي بنجاح";

  static const Map<String, String> activityLevels = {
    "sedentary": "قليل الحركة",
    "light": "نشاط خفيف",
    "moderate": "نشاط متوسط",
    "active": "نشيط",
  };

  static const Map<String, String> socialSupportLevels = {
    "none": "لا يوجد دعم",
    "low": "دعم محدود",
    "medium": "دعم متوسط",
    "high": "دعم قوي",
  };

  // Home
  static const String home = "الرئيسية";
  static const String welcomeBack = "أهلاً بعودتك";
  static const String howAreYouToday = "كيف تشعر اليوم؟";
  static const String startInterview = "بدء محادثة تفاعلية";
  static const String continueInterview = "إكمال المحادثة الحالية";
  static const String latestRiskLevel = "آخر تقييم لحالتك النفسية";
  static const String noAssessmentYet = "لا يوجد تقييم متاح بعد. ابدأ محادثة لمعرفة حالتك.";
  static const String quickMoodLog = "تسجيل سريع للحالة المزاجية";

  // Risk levels
  static const Map<int, String> riskLevelLabels = {
    1: "مستقرة",
    2: "قلق خفيف",
    3: "خطر متوسط",
    4: "خطر مرتفع",
    5: "يتطلب اهتماماً عاجلاً",
  };

  // Chat / Interview
  static const String chatTitle = "المحادثة التفاعلية";
  static const String typeYourAnswer = "اكتب إجابتك هنا...";
  static const String send = "إرسال";
  static const String sessionEnded = "انتهت الجلسة";
  static const String startNewSession = "بدء جلسة جديدة";
  static const String endSessionEarly = "إنهاء الجلسة";
  static const String endSessionConfirm = "هل تريد إنهاء هذه الجلسة الآن؟";
  static const String yes = "نعم";
  static const String no = "لا، أكمل";
  static const String scaleQuestionHint = "اختر تقييماً من 1 إلى 5";
  static const String activeSessionExists = "توجد جلسة مفتوحة بالفعل";

  // Mood
  static const String moodTracker = "تتبع الحالة المزاجية";
  static const String howIsYourMood = "كيف تصف حالتك المزاجية الآن؟";
  static const String addNote = "أضف ملاحظة (اختياري)";
  static const String saveMood = "حفظ";
  static const String moodSaved = "تم تسجيل حالتك المزاجية";
  static const String moodHistory = "السجل";

  static const Map<int, String> moodLabels = {
    1: "سيئة جداً",
    2: "سيئة",
    3: "عادية",
    4: "جيدة",
    5: "ممتازة",
  };

  // Recommendations
  static const String recommendations = "التوصيات";
  static const String noRecommendations = "لا توجد توصيات حالياً";
  static const String wasThisHelpful = "هل كانت هذه التوصية مفيدة؟";
  static const String thankYouForFeedback = "شكراً لملاحظاتك";

  static const Map<String, String> recommendationCategoryLabels = {
    "breathing_exercise": "تمرين تنفس",
    "relaxation": "استرخاء",
    "sleep_tip": "نصيحة للنوم",
    "stress_management": "إدارة التوتر",
    "motivational": "رسالة تحفيزية",
    "educational": "محتوى تعليمي",
    "professional_help": "دعم متخصص",
  };

  // Reports
  static const String reports = "التقارير";
  static const String dailyReport = "تقرير اليوم";
  static const String weeklyReport = "تقرير الأسبوع";
  static const String monthlyReport = "تقرير الشهر";
  static const String moodTrend = "اتجاه الحالة المزاجية";
  static const String riskProgression = "تطور مستوى الخطر";
  static const String noDataYet = "لا توجد بيانات كافية حتى الآن";

  // Notifications
  static const String notifications = "الإشعارات";
  static const String noNotifications = "لا توجد إشعارات";

  // Profile
  static const String profile = "حسابي";
  static const String editProfile = "تعديل الملف الشخصي";
  static const String settings = "الإعدادات";
  static const String myConditions = "أمراضي المزمنة";

  // Common
  static const String save = "حفظ";
  static const String cancel = "إلغاء";
  static const String retry = "إعادة المحاولة";
  static const String loading = "جارِ التحميل...";
  static const String somethingWentWrong = "حدث خطأ ما، حاول مرة أخرى";
  static const String requiredField = "هذا الحقل مطلوب";
  static const String ok = "حسناً";

  // Disclaimer
  static const String disclaimer =
      "هذا التطبيق لا يقدم تشخيصاً طبياً أو نفسياً، ولا يُعد بديلاً عن استشارة الطبيب أو المختص.";
}
