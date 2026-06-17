import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:psych_support_app/core/localization/app_strings.dart';
import 'package:psych_support_app/presentation/shared/risk_badge.dart';

Widget _wrap(Widget child) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: MaterialApp(home: Scaffold(body: Center(child: child))),
  );
}

void main() {
  group('RiskLevelBadge', () {
    testWidgets('renders the Arabic label and level number for each risk level', (tester) async {
      for (var level = 1; level <= 5; level++) {
        await tester.pumpWidget(_wrap(RiskLevelBadge(riskLevel: level)));

        final expectedLabel = AppStrings.riskLevelLabels[level]!;
        expect(find.text('المستوى $level · $expectedLabel'), findsOneWidget);
      }
    });

    testWidgets('large variant renders larger dot and text', (tester) async {
      await tester.pumpWidget(_wrap(const RiskLevelBadge(riskLevel: 3, large: true)));

      final text = tester.widget<Text>(find.textContaining('المستوى 3'));
      expect(text.style?.fontSize, 14);

      // The colored indicator dot should be 12x12 in the large variant.
      final dotFinder = find.descendant(
        of: find.byType(RiskLevelBadge),
        matching: find.byWidgetPredicate(
          (widget) => widget is Container && widget.constraints?.maxWidth == 12,
        ),
      );
      expect(dotFinder, findsOneWidget);
    });

    testWidgets('small variant (default) renders an 8x8 indicator dot', (tester) async {
      await tester.pumpWidget(_wrap(const RiskLevelBadge(riskLevel: 1)));

      final dotFinder = find.descendant(
        of: find.byType(RiskLevelBadge),
        matching: find.byWidgetPredicate(
          (widget) => widget is Container && widget.constraints?.maxWidth == 8,
        ),
      );
      expect(dotFinder, findsOneWidget);
    });

    testWidgets('falls back to an empty label for an unknown risk level', (tester) async {
      await tester.pumpWidget(_wrap(const RiskLevelBadge(riskLevel: 99)));

      // Should still render "المستوى 99 - " without crashing, even though
      // AppStrings.riskLevelLabels has no entry for 99.
      expect(find.textContaining('المستوى 99'), findsOneWidget);
    });
  });
}
