import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/invoice_model.dart';
import '../../services/invoice_service.dart';
import 'payment_detail_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final _service = InvoiceService();
  late Future<List<InvoiceModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getAllInvoices();
  }

  void _reload() {
    setState(() => _future = _service.getAllInvoices());
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch sử hoá đơn',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<List<InvoiceModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }

          final invoices = snapshot.data ?? [];

          if (invoices.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Chưa có hoá đơn nào',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final inv = invoices[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PaymentDetailScreen(invoice: inv)),
                    );
                    _reload(); // refresh sau khi quay lại
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      // Badge tháng
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(children: [
                          Text('T${inv.month.month}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                          Text('${inv.month.year}',
                              style: const TextStyle(
                                  color: AppColors.primary, fontSize: 10)),
                        ]),
                      ),
                      const SizedBox(width: 16),
                      // Thông tin
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(inv.room.roomName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textDark)),
                            const SizedBox(height: 2),
                            Text(fmt.format(inv.totalAmount),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark)),
                            const SizedBox(height: 4),
                            Text('Điện: ${inv.electricityUsed.toInt()} số',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 13)),
                          ],
                        ),
                      ),
                      // Trạng thái
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: inv.isPaid
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              inv.isPaid ? 'Đã trả' : 'Chưa trả',
                              style: TextStyle(
                                  color:
                                      inv.isPaid ? Colors.green : Colors.orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Icon(Icons.chevron_right,
                              color: Colors.grey, size: 20),
                        ],
                      ),
                    ]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
