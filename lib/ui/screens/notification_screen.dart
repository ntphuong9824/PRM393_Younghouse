import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Thông báo bảo trì định kỳ',
      'message': 'Hệ thống sẽ bảo trì vào ngày 15/03/2026 từ 22:00 - 24:00.',
      'time': '2026-03-10 10:00',
      'isRead': false,
    },
    {
      'title': 'Cập nhật hợp đồng',
      'message': 'Hợp đồng phòng 302 đã được cập nhật. Vui lòng kiểm tra.',
      'time': '2026-03-08 14:30',
      'isRead': true,
    },
    {
      'title': 'Thanh toán thành công',
      'message': 'Thanh toán tiền thuê nhà tháng 02/2026 đã được xử lý.',
      'time': '2026-03-05 09:15',
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Thông báo", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                notification['isRead'] ? Icons.notifications_none : Icons.notifications,
                color: notification['isRead'] ? Colors.grey : AppColors.primary,
              ),
              title: Text(
                notification['title'],
                style: TextStyle(
                  fontWeight: notification['isRead'] ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification['message']),
                  const SizedBox(height: 4),
                  Text(
                    notification['time'],
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              onTap: () {
                // Mark as read
                setState(() {
                  _notifications[index]['isRead'] = true;
                });
                // TODO: Navigate to detail if needed
              },
            ),
          );
        },
      ),
    );
  }
}
