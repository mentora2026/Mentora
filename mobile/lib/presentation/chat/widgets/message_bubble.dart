import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/interview.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isBot = message.isBot;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Align(
        alignment: isBot ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isBot) ...[
              _BotAvatar(),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: Container(
                key: const ValueKey('message-bubble'),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: isBot ? AppColors.botBubble : AppColors.patientBubble,
                  borderRadius: BorderRadius.only(
                    topRight: const Radius.circular(AppSpacing.radiusMd),
                    topLeft: const Radius.circular(AppSpacing.radiusMd),
                    bottomRight: Radius.circular(isBot ? 4 : AppSpacing.radiusMd),
                    bottomLeft: Radius.circular(isBot ? AppSpacing.radiusMd : 4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isBot ? 0.04 : 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isBot)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          "مساعد الدعم",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                        ),
                      ),
                    Text(
                      message.messageTextAr,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isBot ? AppColors.textPrimary : Colors.white,
                            height: 1.55,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.Hm().format(message.createdAt),
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isBot ? AppColors.textTertiary : Colors.white70,
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (!isBot) const SizedBox(width: 36),
            if (isBot) const SizedBox(width: 36),
          ],
        ),
      ),
    );
  }
}

class _BotAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: const Icon(Icons.psychology_outlined, size: 18, color: AppColors.primary),
    );
  }
}
