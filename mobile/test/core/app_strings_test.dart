import 'package:flutter_test/flutter_test.dart';
import 'package:psych_support_app/core/localization/app_strings.dart';
import 'package:psych_support_app/data/models/interview.dart';
import 'package:psych_support_app/providers/interview_provider.dart';

void main() {
  group('AppStrings label maps', () {
    test('riskLevelLabels covers all 5 risk levels with non-empty Arabic text', () {
      for (var level = 1; level <= 5; level++) {
        final label = AppStrings.riskLevelLabels[level];
        expect(label, isNotNull, reason: 'Missing label for risk level $level');
        expect(label, isNotEmpty);
      }
    });

    test('moodLabels covers all 5 mood values with non-empty Arabic text', () {
      for (var value = 1; value <= 5; value++) {
        final label = AppStrings.moodLabels[value];
        expect(label, isNotNull, reason: 'Missing label for mood value $value');
        expect(label, isNotEmpty);
      }
    });

    test('recommendationCategoryLabels covers all backend categories', () {
      const backendCategories = [
        'breathing_exercise',
        'relaxation',
        'sleep_tip',
        'stress_management',
        'motivational',
        'educational',
        'professional_help',
      ];

      for (final category in backendCategories) {
        final label = AppStrings.recommendationCategoryLabels[category];
        expect(label, isNotNull, reason: 'Missing label for category "$category"');
        expect(label, isNotEmpty);
      }
    });

    test('activityLevels covers all backend activity levels', () {
      const backendLevels = ['sedentary', 'light', 'moderate', 'active'];
      for (final level in backendLevels) {
        expect(AppStrings.activityLevels[level], isNotNull, reason: 'Missing label for "$level"');
      }
    });

    test('socialSupportLevels covers all backend support levels', () {
      const backendLevels = ['none', 'low', 'medium', 'high'];
      for (final level in backendLevels) {
        expect(AppStrings.socialSupportLevels[level], isNotNull, reason: 'Missing label for "$level"');
      }
    });
  });

  group('InterviewProvider.reset', () {
    test('clears all session state', () {
      final provider = InterviewProvider();

      provider.messages.add(
        ChatMessage(
          id: 'm1',
          sender: 'bot',
          messageTextAr: 'مرحباً',
          messageOrder: 1,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      provider.sessionEnded = true;
      provider.lastRiskAssessmentId = 'risk-1';
      provider.errorMessageAr = 'خطأ';

      provider.reset();

      expect(provider.currentSession, isNull);
      expect(provider.messages, isEmpty);
      expect(provider.sessionEnded, isFalse);
      expect(provider.lastRiskAssessmentId, isNull);
      expect(provider.errorMessageAr, isNull);
    });
  });
}
