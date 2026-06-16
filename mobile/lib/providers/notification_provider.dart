import 'package:flutter/foundation.dart';

import '../data/models/extras.dart';
import '../data/repositories/extras_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();

  List<AppNotification> notifications = [];
  bool isLoading = false;
  String? errorMessageAr;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  Future<void> load() async {
    isLoading = true;
    errorMessageAr = null;
    notifyListeners();

    try {
      notifications = await _repository.getNotifications();
    } catch (e) {
      errorMessageAr = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead) return;
    try {
      await _repository.markRead(notification.id);
      final index = notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        notifications[index] = AppNotification(
          id: notification.id,
          type: notification.type,
          titleAr: notification.titleAr,
          bodyAr: notification.bodyAr,
          isRead: true,
          status: notification.status,
          createdAt: notification.createdAt,
        );
        notifyListeners();
      }
    } catch (_) {
      // Non-critical.
    }
  }
}
