import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/interview.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isBot = message.isBot;

    return Align(
      alignment: isBot ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isBot ? AppColors.primaryLight : AppColors.primary,
          borderRadius: BorderRadius.only(
            topRight: const Radius.circular(16),
            topLeft: const Radius.circular(16),
            bottomRight: Radius.circular(isBot ? 4 : 16),
            bottomLeft: Radius.circular(isBot ? 16 : 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.messageTextAr,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isBot ? AppColors.textPrimary : Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat.Hm().format(message.createdAt),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isBot ? AppColors.textSecondary : Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
