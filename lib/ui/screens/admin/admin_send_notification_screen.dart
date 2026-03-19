import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/notification_model.dart';
import '../../../providers/notification_provider.dart';
import 'notification_detail_screen.dart';

class AdminSendNotificationScreen extends StatefulWidget {
  final String landlordId;
  const AdminSendNotificationScreen({super.key, required this.landlordId});

  @override
  State<AdminSendNotificationScreen> createState() =>
      _AdminSendNotificationScreenState();
}

class _AdminSendNotificationScreenState
    extends State<AdminSendNotificationScreen>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<NotificationProvider>()
          .listenToNotifications(widget.landlordId);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề và nội dung')),
      );
      return;
    }
    setState(() => _isSending = true);
    try {
      await context.read<NotificationProvider>().sendNotification(
            title: title,
            message: message,
          );
      if (mounted) {
        _titleController.clear();
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi thông báo thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _confirmDelete(NotificationModel n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá thông báo'),
        content: Text('Xoá "${n.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<NotificationProvider>().deleteNotification(n.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thông báo',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Đã nhận'),
            Tab(text: 'Đã gửi'),
          ],
        ),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          final all = provider.notifications;

          // Nhận: targetUserId = landlordId (từ tenant gửi lên)
          final received = all
              .where((n) => n.targetUserId == widget.landlordId)
              .toList();

          // Đã gửi: targetUserId = null (broadcast) hoặc là tenant
          final sent = all
              .where((n) => n.targetUserId != widget.landlordId)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _ReceivedTab(
                notifications: received,
                landlordId: widget.landlordId,
                onDelete: _confirmDelete,
              ),
              _SentTab(
                titleController: _titleController,
                messageController: _messageController,
                isSending: _isSending,
                onSend: _send,
                notifications: sent,
                landlordId: widget.landlordId,
                onDelete: _confirmDelete,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Tab Đã nhận ──────────────────────────────────────────────
class _ReceivedTab extends StatefulWidget {
  final List<NotificationModel> notifications;
  final String landlordId;
  final Future<void> Function(NotificationModel) onDelete;

  const _ReceivedTab({
    required this.notifications,
    required this.landlordId,
    required this.onDelete,
  });

  @override
  State<_ReceivedTab> createState() => _ReceivedTabState();
}

class _ReceivedTabState extends State<_ReceivedTab> {
  static const _pageSize = 10;
  int _page = 0;

  @override
  void didUpdateWidget(_ReceivedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset về trang đầu khi danh sách thay đổi
    if (oldWidget.notifications.length != widget.notifications.length) {
      _page = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Chưa có thông báo nào',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    final total = widget.notifications.length;
    final totalPages = (total / _pageSize).ceil();
    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, total);
    final paged = widget.notifications.sublist(start, end);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: paged.length,
            itemBuilder: (context, index) {
              final n = paged[index];
              final isRead = n.isReadBy(widget.landlordId);
              return _NotifCard(
                notification: n,
                isRead: isRead,
                onTap: () async {
                  await context
                      .read<NotificationProvider>()
                      .markAsRead(n.id, widget.landlordId);
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            NotificationDetailScreen(notification: n)),
                  );
                },
                onDelete: () => widget.onDelete(n),
              );
            },
          ),
        ),
        if (totalPages > 1)
          _PaginationBar(
            currentPage: _page,
            totalPages: totalPages,
            onPageChanged: (p) => setState(() => _page = p),
          ),
      ],
    );
  }
}

// ── Tab Đã gửi ───────────────────────────────────────────────
class _SentTab extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController messageController;
  final bool isSending;
  final VoidCallback onSend;
  final List<NotificationModel> notifications;
  final String landlordId;
  final Future<void> Function(NotificationModel) onDelete;

  const _SentTab({
    required this.titleController,
    required this.messageController,
    required this.isSending,
    required this.onSend,
    required this.notifications,
    required this.landlordId,
    required this.onDelete,
  });

  @override
  State<_SentTab> createState() => _SentTabState();
}

class _SentTabState extends State<_SentTab> {
  static const _pageSize = 10;
  int _page = 0;

  @override
  void didUpdateWidget(_SentTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifications.length != widget.notifications.length) {
      _page = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.notifications.length;
    final totalPages = total == 0 ? 0 : (total / _pageSize).ceil();
    final start = _page * _pageSize;
    final end = total == 0 ? 0 : (start + _pageSize).clamp(0, total);
    final paged = total == 0 ? <NotificationModel>[] : widget.notifications.sublist(start, end);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gửi thông báo đến tất cả người thuê',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: widget.titleController,
                  decoration: InputDecoration(
                    labelText: 'Tiêu đề thông báo',
                    prefixIcon: const Icon(Icons.title, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: widget.messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Nội dung thông báo',
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 56),
                      child: Icon(Icons.message_outlined,
                          color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: widget.isSending ? null : widget.onSend,
                    icon: widget.isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, color: Colors.white),
                    label: Text(
                      widget.isSending ? 'Đang gửi...' : 'GỬI THÔNG BÁO',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Lịch sử đã gửi',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 12),
                if (paged.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Chưa có thông báo nào',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ...paged.map(
                    (n) => _NotifCard(
                      notification: n,
                      isRead: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                NotificationDetailScreen(notification: n)),
                      ),
                      onDelete: () => widget.onDelete(n),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (totalPages > 1)
          _PaginationBar(
            currentPage: _page,
            totalPages: totalPages,
            onPageChanged: (p) => setState(() => _page = p),
          ),
      ],
    );
  }
}

// ── Card dùng chung ──────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final NotificationModel notification;
  final bool isRead;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotifCard({
    required this.notification,
    required this.isRead,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isRead ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRead
            ? BorderSide(color: Colors.grey.shade200)
            : const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isRead
                        ? Colors.grey.shade100
                        : AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRead
                        ? Icons.notifications_none
                        : Icons.notifications,
                    color: isRead ? Colors.grey : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormatter.formatWithTime(
                              notification.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ]),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                  ),
                ]),
              ]),
        ),
      ),
    );
  }
}

// ── Pagination bar dùng chung ────────────────────────────────
class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final void Function(int) onPageChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
            color: AppColors.primary,
          ),
          ...List.generate(totalPages, (i) {
            final selected = i == currentPage;
            return GestureDetector(
              onTap: () => onPageChanged(i),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages - 1
                ? () => onPageChanged(currentPage + 1)
                : null,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
