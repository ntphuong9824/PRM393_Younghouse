import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int unreadCount(String userId) => _notifications
      .where((n) => n.targetUserId == userId && !n.isReadBy(userId))
      .length;

  void listenToNotifications(String userId) {
    // Hủy stream cũ trước khi tạo mới
    _subscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription = _service.getNotificationsStream(userId).listen(
      (list) {
        _notifications = list;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(String notificationId, String userId) async {
    await _service.markAsRead(notificationId, userId);
  }

  Future<void> sendNotification({
    required String title,
    required String message,
    String? targetUserId,
  }) async {
    await _service.sendNotification(
      title: title,
      message: message,
      targetUserId: targetUserId,
    );
  }

  Future<void> deleteNotification(String notificationId) async {
    await _service.deleteNotification(notificationId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
