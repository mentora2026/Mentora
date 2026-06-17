import 'package:flutter/material.dart';

/// Calming clinical palette aligned with the admin dashboard identity.
class AppColors {
  AppColors._();

  // Brand — deep teal anchor
  static const Color primary = Color(0xFF0F3D3E);
  static const Color primaryDark = Color(0xFF0A2E2F);
  static const Color primaryLight = Color(0xFFE4EFEF);
  static const Color primaryMuted = Color(0xFF6B8E8E);

  static const Color secondary = Color(0xFF3D6B6C);
  static const Color secondaryLight = Color(0xFFDCEAEA);
  static const Color accent = Color(0xFFC9622D);

  // Surfaces
  static const Color background = Color(0xFFF6F5F1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEDEAE3);
  static const Color surfaceElevated = Color(0xFFFFFCF8);

  // Text
  static const Color textPrimary = Color(0xFF1A2E2E);
  static const Color textSecondary = Color(0xFF6B8E8E);
  static const Color textTertiary = Color(0xFF9AAFAF);

  static const Color border = Color(0xFFE8E4DC);
  static const Color borderFocus = Color(0xFF0F3D3E);

  // Risk levels (1 = stable → 5 = critical) — matches admin dashboard
  static const Color risk1 = Color(0xFF4F8A5B);
  static const Color risk2 = Color(0xFF8BAA4E);
  static const Color risk3 = Color(0xFFD4A12C);
  static const Color risk4 = Color(0xFFD9763B);
  static const Color risk5 = Color(0xFFC1432E);

  static Color riskColor(int level) {
    switch (level) {
      case 1:
        return risk1;
      case 2:
        return risk2;
      case 3:
        return risk3;
      case 4:
        return risk4;
      case 5:
        return risk5;
      default:
        return textSecondary;
    }
  }

  static Color riskBackground(int level) => riskColor(level).withValues(alpha: 0.12);

  // Mood scale
  static const Color moodLow = Color(0xFFE57373);
  static const Color moodMid = Color(0xFFFFD54F);
  static const Color moodHigh = Color(0xFF81C784);

  // Chat
  static const Color botBubble = Color(0xFFE4EFEF);
  static const Color patientBubble = Color(0xFF0F3D3E);
}
