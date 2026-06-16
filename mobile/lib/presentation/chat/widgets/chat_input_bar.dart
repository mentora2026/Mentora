import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Input bar for the adaptive interview chat.
///
/// Provides a free-text field (used for `open_text` questions) and a
/// secondary "1-5 scale" picker the patient can open for `scale_1_5` /
/// rating-style questions. The backend determines question semantics;
/// this UI simply lets the patient choose whichever input type fits the
/// question they were just asked.
class ChatInputBar extends StatefulWidget {
  final bool isSending;
  final bool isEnabled;
  final void Function({String? textAr, num? valueNumeric}) onSend;

  const ChatInputBar({
    super.key,
    required this.isSending,
    required this.isEnabled,
    required this.onSend,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  bool _showScalePicker = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(textAr: text);
    _controller.clear();
    setState(() => _showScalePicker = false);
  }

  void _sendScale(int value) {
    widget.onSend(valueNumeric: value);
    setState(() => _showScalePicker = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, -2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showScalePicker) _ScalePicker(onSelect: _sendScale),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _showScalePicker ? Icons.keyboard_alt_outlined : Icons.linear_scale,
                    color: AppColors.primary,
                  ),
                  tooltip: AppStrings.scaleQuestionHint,
                  onPressed: widget.isEnabled
                      ? () => setState(() => _showScalePicker = !_showScalePicker)
                      : null,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: widget.isEnabled,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendText(),
                    decoration: const InputDecoration(
                      hintText: AppStrings.typeYourAnswer,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                widget.isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send, color: AppColors.primary),
                        onPressed: widget.isEnabled ? _sendText : null,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScalePicker extends StatelessWidget {
  final void Function(int value) onSelect;

  const _ScalePicker({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          const Text(AppStrings.scaleQuestionHint, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final value = index + 1;
              return InkWell(
                onTap: () => onSelect(value),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    "$value",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
