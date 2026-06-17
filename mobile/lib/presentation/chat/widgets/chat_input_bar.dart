import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Input bar for the adaptive interview chat.
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
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

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

  bool get _canSend => widget.isEnabled && !widget.isSending && _controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.8))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showScalePicker) _ScalePicker(onSelect: _sendScale),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Material(
                    color: _showScalePicker ? AppColors.primaryLight : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      onTap: widget.isEnabled
                          ? () => setState(() => _showScalePicker = !_showScalePicker)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          _showScalePicker ? Icons.keyboard_alt_outlined : Icons.linear_scale_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _controller,
                        enabled: widget.isEnabled,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _canSend ? _sendText() : null,
                        decoration: InputDecoration(
                          hintText: AppStrings.typeYourAnswer,
                          hintStyle: Theme.of(context).textTheme.bodySmall,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  widget.isSending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                        )
                      : Material(
                          color: _canSend ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
                            onTap: _canSend ? _sendText : null,
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                ],
              ),
            ],
          ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Text(
            AppStrings.scaleQuestionHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final value = index + 1;
              return Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: InkWell(
                  onTap: () => onSelect(value),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      "$value",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontSize: 16,
                          ),
                    ),
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
