import 'package:flutter/material.dart';

/// Calming, supportive color palette suited for a mental-health-oriented app.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF3D7A6E); // calm teal/green
  static const Color primaryLight = Color(0xFFDCEDE8);
  static const Color secondary = Color(0xFF6C8EBF); // soft blue
  static const Color background = Color(0xFFF7F9F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2B2B2B);
  static const Color textSecondary = Color(0xFF6F6F6F);

  // Risk level colors (1 = stable -> 5 = critical)
  static const Color risk1 = Color(0xFF4CAF50);
  static const Color risk2 = Color(0xFF8BC34A);
  static const Color risk3 = Color(0xFFFFC107);
  static const Color risk4 = Color(0xFFFF7043);
  static const Color risk5 = Color(0xFFE53935);

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

  // Mood colors (1 = very low -> 5 = very good)
  static const Color moodLow = Color(0xFFE57373);
  static const Color moodMid = Color(0xFFFFD54F);
  static const Color moodHigh = Color(0xFF81C784);
}
