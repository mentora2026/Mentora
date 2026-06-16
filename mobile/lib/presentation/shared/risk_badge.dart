import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';

class RiskLevelBadge extends StatelessWidget {
  final int riskLevel;
  final bool large;

  const RiskLevelBadge({super.key, required this.riskLevel, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.riskColor(riskLevel);
    final label = AppStrings.riskLevelLabels[riskLevel] ?? "";

    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 16 : 12, vertical: large ? 10 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: large ? 12 : 8,
            height: large ? 12 : 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            "المستوى $riskLevel - $label",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: large ? 16 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
