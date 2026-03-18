import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../services/invoice_service.dart';
import 'payment_history_screen.dart';
import 'payment_detail_screen.dart';
import 'select_invoice_screen.dart';
import 'create_invoice_screen.dart';
import 'chat_support_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String roomInfo;

  const MainScreen({
    super.key,
    this.userId = 'user_001',
    this.userName = 'Nguyễn Văn A',
    this.roomInfo = 'Phòng 302 - Nhà Young House 1',
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final _invoiceService = InvoiceService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().listenToNotifications(widget.userId);
      // Listen chat rooms để hiện badge unread
      context.read<ChatProvider>().listenChatRoomsForTenant(widget.userId);
    });
  }

  Future<void> _onFeatureTap(String title) async {
    if (title == 'Thanh toán') {
      final invoices = await _invoiceService.getInvoicesByTenant(widget.userId);
      final unpaid = invoices.where((i) => i.status != 'paid').toList();
      if (!mounted) return;
      if (unpaid.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không có hoá đơn nào cần thanh toán'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (unpaid.length == 1) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentDetailScreen(invoice: unpaid.first),
          ),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SelectInvoiceScreen(tenantId: widget.userId)),
        );
      }
    } else if (title == 'Tạo hoá đơn') {
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CreateInvoiceScreen(tenantId: widget.userId)),
      );
    } else if (title == 'Thông báo') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NotificationScreen(userId: widget.userId),
        ),
      );
    }
  }

  void _onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatSupportScreen(
            userId: widget.userId,
            userName: widget.userName,
          ),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentHistoryScreen(tenantId: widget.userId),
        ),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            userId: widget.userId,
            userName: widget.userName,
          ),
        ),
      );
    }
  }

  final List<Map<String, dynamic>> _features = [
    {
      'title': 'Thông báo',
      'icon': Icons.notifications_active_outlined,
      'color': Colors.orange,
    },
    {
      'title': 'Hợp đồng',
      'icon': Icons.assignment_outlined,
      'color': Colors.blue,
    },
    {
      'title': 'Thanh toán',
      'icon': Icons.account_balance_wallet_outlined,
      'color': Colors.green,
    },
    {
      'title': 'Tạo hoá đơn',
      'icon': Icons.receipt_long_outlined,
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Young House',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    userId: widget.userId,
                    userName: widget.userName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Xin chào,',
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.roomInfo,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Text(
                'Dịch vụ tiện ích',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer<NotificationProvider>(
                builder: (context, provider, _) {
                  final unread = provider.unreadCount(widget.userId);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _features.length,
                    itemBuilder: (context, index) {
                      final item = _features[index];
                      final count = item['title'] == 'Thông báo' && unread > 0
                          ? unread.toString()
                          : null;
                      return _buildFeatureCard(item, count);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Consumer<ChatProvider>(
        builder: (context, chatProvider, _) {
          final unreadChat = chatProvider.totalUnreadByTenant;
          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onBottomNavTap,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey,
            items: [
              const BottomNavigationBarItem(
                  icon: Icon(Icons.home), label: 'Trang chủ'),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: unreadChat > 0,
                  label: Text('$unreadChat'),
                  child: const Icon(Icons.chat_bubble_outline),
                ),
                label: 'Hỗ trợ',
              ),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.history), label: 'Lịch sử'),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline), label: 'Tài khoản'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> item, String? count) {
    return InkWell(
      onTap: () => _onFeatureTap(item['title']),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['icon'],
                      color: item['color'] as Color, size: 28),
                ),
                if (count != null)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: Text(
                        count,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              item['title'],
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }
}
