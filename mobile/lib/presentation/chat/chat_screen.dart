import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/interview_provider.dart';
import '../shared/app_card.dart';
import '../shared/state_views.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/message_bubble.dart';
import 'widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<InterviewProvider>();
      await provider.initialize();
      if (provider.currentSession == null) {
        await provider.startNewSession();
      }
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _confirmEndSession() async {
    final provider = context.read<InterviewProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.endSessionEarly),
        content: const Text(AppStrings.endSessionConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.no)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AppStrings.yes)),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.endSessionEarly();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InterviewProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          children: [
            Text(AppStrings.chatTitle,
                style: Theme.of(context).textTheme.titleMedium),
            Text(
              "مساحة آمنة للمحادثة",
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ],
        ),
        actions: [
          if (provider.currentSession != null && !provider.sessionEnded)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined),
              tooltip: AppStrings.endSessionEarly,
              onPressed: provider.isSending ? null : _confirmEndSession,
            ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (provider.isLoading && provider.messages.isEmpty) {
              return const LoadingView();
            }

            if (provider.errorMessageAr != null && provider.messages.isEmpty) {
              return ErrorView(
                messageAr: provider.errorMessageAr!,
                onRetry: () => provider.startNewSession(),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    itemCount:
                        provider.messages.length + (provider.isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.messages.length) {
                        return const TypingIndicator();
                      }
                      return MessageBubble(message: provider.messages[index]);
                    },
                  ),
                ),
                if (provider.sessionEnded)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: AppCard(
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              color: AppColors.risk1, size: 36),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            AppStrings.sessionEnded,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            "شكراً لمشاركتك. يمكنك مراجعة التوصيات والتقارير من الصفحة الرئيسية.",
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(height: 1.5),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FilledButton(
                            onPressed: () async {
                              await provider.startNewSession();
                              _scrollToBottom();
                            },
                            child: const Text(AppStrings.startNewSession),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ChatInputBar(
                    isSending: provider.isSending,
                    isEnabled: provider.currentSession != null &&
                        !provider.sessionEnded,
                    onSend: ({textAr, valueNumeric}) async {
                      await provider.sendAnswer(
                          textAr: textAr, valueNumeric: valueNumeric);
                      _scrollToBottom();
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
