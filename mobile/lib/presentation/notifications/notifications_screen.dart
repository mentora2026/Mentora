import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/extras.dart';
import '../../providers/notification_provider.dart';
import '../shared/app_card.dart';
import '../shared/main_shell.dart';
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
    final unreadCount =
        provider.notifications.where((item) => !item.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.notifications),
        actions: [
          if (provider.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: "مسح جميع الإشعارات",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("مسح جميع الإشعارات"),
                    content: const Text("هل أنت متأكد من رغبتك في تنظيف سجل الإشعارات بالكامل؟"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("إلغاء"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          provider.clearAll();
                        },
                        child: const Text("مسح", style: TextStyle(color: AppColors.risk5)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.load(),
          child: Builder(
            builder: (context) {
              if (provider.isLoading && provider.notifications.isEmpty) {
                return const LoadingView();
              }
              if (provider.errorMessageAr != null &&
                  provider.notifications.isEmpty) {
                return ErrorView(
                    messageAr: provider.errorMessageAr!,
                    onRetry: () => provider.load());
              }
              if (provider.notifications.isEmpty) {
                return const EmptyView(
                    messageAr: AppStrings.noNotifications,
                    icon: Icons.notifications_none_rounded);
              }

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _NotificationsHeader(
                      total: provider.notifications.length,
                      unread: unreadCount),
                  const SizedBox(height: AppSpacing.md),
                  ...provider.notifications.map((notification) =>
                      _NotificationTile(notification: notification)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  final int total;
  final int unread;

  const _NotificationsHeader({required this.total, required this.unread});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(Icons.notifications_active_outlined,
                color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unread == 0
                      ? 'كل الإشعارات مقروءة'
                      : '$unread إشعارات غير مقروءة',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'إجمالي الإشعارات: $total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  IconData get _icon {
    return switch (notification.type) {
      'daily_checkin' => Icons.event_available_outlined,
      'follow_up' => Icons.replay_outlined,
      'mood_reminder' => Icons.emoji_emotions_outlined,
      'recommendation_alert' => Icons.lightbulb_outline_rounded,
      'risk_alert_admin' => Icons.warning_amber_rounded,
      _ => Icons.notifications_none_rounded,
    };
  }

  Color get _accent {
    return switch (notification.type) {
      'risk_alert_admin' => AppColors.risk5,
      'recommendation_alert' => AppColors.accent,
      'mood_reminder' => AppColors.moodHigh,
      _ => AppColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return AppCard(
      onTap: () {
        context.read<NotificationProvider>().markRead(notification);
        if (notification.type == 'recommendation_alert') {
          MainShell.switchTab(1);
        }
      },
      color: isUnread
          ? AppColors.primaryLight.withValues(alpha: 0.55)
          : AppColors.surface,
      borderSide: BorderSide(
          color: isUnread
              ? AppColors.primary.withValues(alpha: 0.16)
              : AppColors.border),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(_icon, color: _accent),
              ),
              if (isUnread)
                PositionedDirectional(
                  top: -2,
                  end: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                        color: AppColors.accent, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(notification.titleAr,
                          style: Theme.of(context).textTheme.titleSmall),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      DateFormat('d/M HH:mm').format(notification.createdAt),
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  notification.bodyAr,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textTertiary, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              context.read<NotificationProvider>().deleteNotification(notification.id);
            },
          ),
        ],
      ),
    );
  }
}
