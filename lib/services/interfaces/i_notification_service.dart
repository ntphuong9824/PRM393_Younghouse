import '../../models/notification_model.dart';

abstract class INotificationService {
  Future<void> initialize();
  Future<void> saveUserToken(String userId);
  Future<void> sendNotification({
    required String title,
    required String message,
    String? targetUserId,
  });
  Stream<List<NotificationModel>> getNotificationsStream(String userId);
  Future<void> markAsRead(String notificationId, String userId);
}
