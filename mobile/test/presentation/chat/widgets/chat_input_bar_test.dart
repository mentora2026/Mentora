import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:psych_support_app/presentation/chat/widgets/chat_input_bar.dart';

Widget _wrap(Widget child) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void _noop({String? textAr, num? valueNumeric}) {}

void main() {
  group('ChatInputBar', () {
    testWidgets('sends trimmed text and clears the field on submit', (tester) async {
      String? sentText;
      num? sentValue;

      await tester.pumpWidget(
        _wrap(
          ChatInputBar(
            isSending: false,
            isEnabled: true,
            onSend: ({textAr, valueNumeric}) {
              sentText = textAr;
              sentValue = valueNumeric;
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '  أشعر بالقلق  ');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(sentText, 'أشعر بالقلق');
      expect(sentValue, isNull);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);
    });

    testWidgets('does not send when the text field is empty', (tester) async {
      var callCount = 0;

      await tester.pumpWidget(
        _wrap(
          ChatInputBar(
            isSending: false,
            isEnabled: true,
            onSend: ({textAr, valueNumeric}) => callCount++,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(callCount, 0);
    });

    testWidgets('toggles the 1-5 scale picker and sends a numeric value', (tester) async {
      num? sentValue;
      String? sentText;

      await tester.pumpWidget(
        _wrap(
          ChatInputBar(
            isSending: false,
            isEnabled: true,
            onSend: ({textAr, valueNumeric}) {
              sentText = textAr;
              sentValue = valueNumeric;
            },
          ),
        ),
      );

      // Scale picker is hidden by default.
      expect(find.text('3'), findsNothing);

      await tester.tap(find.byIcon(Icons.linear_scale));
      await tester.pump();

      // Scale picker now shows options 1-5.
      for (final label in ['1', '2', '3', '4', '5']) {
        expect(find.text(label), findsOneWidget);
      }

      await tester.tap(find.text('4'));
      await tester.pump();

      expect(sentValue, 4);
      expect(sentText, isNull);

      // Picker closes after selection.
      expect(find.text('4'), findsNothing);
    });

    testWidgets('disables input and send button when isEnabled is false', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ChatInputBar(
            isSending: false,
            isEnabled: false,
            onSend: _noop,
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);

      final sendButton = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send));
      expect(sendButton.onPressed, isNull);
    });

    testWidgets('shows a loading indicator instead of the send button while sending', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ChatInputBar(
            isSending: true,
            isEnabled: true,
            onSend: _noop,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.send), findsNothing);
    });
  });
}
