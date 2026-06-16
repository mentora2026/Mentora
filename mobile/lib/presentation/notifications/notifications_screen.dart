import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/extras.dart';
import '../../providers/notification_provider.dart';
import '../shared/state_views.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.notifications)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.load(),
          child: Builder(
            builder: (context) {
              if (provider.isLoading && provider.notifications.isEmpty) {
                return const LoadingView();
              }
              if (provider.errorMessageAr != null && provider.notifications.isEmpty) {
                return ErrorView(messageAr: provider.errorMessageAr!, onRetry: () => provider.load());
              }
              if (provider.notifications.isEmpty) {
                return const EmptyView(messageAr: AppStrings.noNotifications, icon: Icons.notifications_none);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.notifications.length,
                itemBuilder: (context, index) {
                  final notification = provider.notifications[index];
                  return _NotificationTile(notification: notification);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  IconData get _icon {
    return switch (notification.type) {
      "daily_checkin" => Icons.event_available_outlined,
      "follow_up" => Icons.replay_outlined,
      "mood_reminder" => Icons.emoji_emotions_outlined,
      "recommendation_alert" => Icons.lightbulb_outline,
      "risk_alert_admin" => Icons.warning_amber_outlined,
      _ => Icons.notifications_none,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.isRead ? null : AppColors.primaryLight.withValues(alpha: 0.5),
      child: ListTile(
        leading: Icon(_icon, color: AppColors.primary),
        title: Text(notification.titleAr, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(notification.bodyAr, style: const TextStyle(height: 1.4)),
        ),
        trailing: Text(
          DateFormat("d/M HH:mm").format(notification.createdAt),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        isThreeLine: true,
        onTap: () => context.read<NotificationProvider>().markRead(notification),
      ),
    );
  }
}
