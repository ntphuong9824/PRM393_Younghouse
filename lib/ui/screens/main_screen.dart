import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'payment_history_screen.dart';
import 'payment_detail_screen.dart';
import 'chat_support_screen.dart';
import 'notification_screen.dart';
import 'create_invoice_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onFeatureTap(String title) {
    if (title == 'Thanh toán') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PaymentDetailScreen()));
    } else if (title == 'Thông báo') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const NotificationScreen()));
    } else if (title == 'Tạo hoá đơn') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()));
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      // Tab Hỗ trợ
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChatSupportScreen()),
      );
    } else if (index == 2) {
      // Tab Lịch sử
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PaymentHistoryScreen()),
      );
    }
  }

  final List<Map<String, dynamic>> _features = [
    {
      'title': 'Thông báo',
      'icon': Icons.notifications_active_outlined,
      'color': Colors.orange,
      'count': '3',
    },
    {
      'title': 'Hợp đồng',
      'icon': Icons.assignment_outlined,
      'color': Colors.blue,
      'count': null,
    },
    {
      'title': 'Thanh toán',
      'icon': Icons.account_balance_wallet_outlined,
      'color': Colors.green,
      'count': null,
    },
    {
      'title': 'Tạo hoá đơn',
      'icon': Icons.receipt_long_outlined,
      'color': AppColors.primary,
      'count': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Young House",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Xin chào,",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    "Nguyễn Văn A",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Phòng 302 - Nhà Young House 1",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Text(
                "Dịch vụ tiện ích",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),

            // Features Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: _features.length,
                itemBuilder: (context, index) {
                  final item = _features[index];
                  return _buildFeatureCard(item);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Trang chủ"),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: "Hỗ trợ"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Lịch sử"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: "Tài khoản"),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> item) {
    return InkWell(
      onTap: () => _onFeatureTap(item['title']),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
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
                    color: item['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['icon'], color: item['color'], size: 28),
                ),
                if (item['count'] != null)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        item['count'],
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
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
