import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:psych_support_app/core/theme/app_colors.dart';
import 'package:psych_support_app/data/models/interview.dart';
import 'package:psych_support_app/presentation/chat/widgets/message_bubble.dart';

Widget _wrap(Widget child) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

ChatMessage _message({required String sender, String text = 'مرحباً'}) {
  return ChatMessage(
    id: '1',
    sender: sender,
    messageTextAr: text,
    messageOrder: 1,
    createdAt: DateTime(2026, 1, 1, 10, 30),
  );
}

void main() {
  group('MessageBubble', () {
    testWidgets('renders the Arabic message text', (tester) async {
      await tester.pumpWidget(_wrap(MessageBubble(message: _message(sender: 'bot', text: 'كيف تشعر اليوم؟'))));

      expect(find.text('كيف تشعر اليوم؟'), findsOneWidget);
    });

    testWidgets('bot messages are right-aligned with the light primary color', (tester) async {
      await tester.pumpWidget(_wrap(MessageBubble(message: _message(sender: 'bot'))));

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, Alignment.centerRight);

      final container = tester.widget<Container>(
        find.byKey(const ValueKey('message-bubble')),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.botBubble);
    });

    testWidgets('patient messages are left-aligned with the primary color', (tester) async {
      await tester.pumpWidget(_wrap(MessageBubble(message: _message(sender: 'patient'))));

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, Alignment.centerLeft);

      final container = tester.widget<Container>(
        find.byKey(const ValueKey('message-bubble')),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.patientBubble);
    });

    testWidgets('renders a formatted timestamp', (tester) async {
      await tester.pumpWidget(_wrap(MessageBubble(message: _message(sender: 'bot'))));

      // DateFormat.Hm() for 10:30 -> "10:30"
      expect(find.textContaining('10:30'), findsOneWidget);
    });
  });
}
