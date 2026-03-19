import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import '../core/interfaces/i_notification_service.dart';

// Handler cho background message (phải là top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase đã được init trước đó, chỉ cần xử lý message
}

class NotificationService implements INotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'yh_notifications',
    'Young House Thông báo',
    description: 'Thông báo từ quản lý nhà trọ',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    // Xin quyền thông báo
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Setup local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Tạo notification channel cho Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Lắng nghe foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Lưu FCM token của user vào Firestore
  Future<void> saveUserToken(String userId) async {
    final token = await _fcm.getToken();
    if (token == null) return;
    await _firestore.collection('users').doc(userId).set(
      {'fcmToken': token, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  /// Admin gửi thông báo (lưu vào Firestore)
  Future<void> sendNotification({
    required String title,
    required String message,
    String? targetUserId,
    Map<String, dynamic>? metadata,
  }) async {
    await _firestore.collection('notifications').add({
      'title': title,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'targetUserId': targetUserId,
      'readBy': [],
      if (metadata != null) 'metadata': metadata,
    });
  }

  /// Stream thông báo realtime cho một user cụ thể
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .where((n) => n.targetUserId == null || n.targetUserId == userId)
              .toList();
          // Sort ở client, tránh cần Firestore index
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Đánh dấu đã đọc
  Future<void> markAsRead(String notificationId, String userId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'readBy': FieldValue.arrayUnion([userId]),
    });
  }

  /// Xoá thông báo
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }
}
