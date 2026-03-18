import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/invoice_model.dart';
import '../../../services/invoice_service.dart';
import 'payment_detail_screen.dart';

class SelectInvoiceScreen extends StatefulWidget {
  final String tenantId;
  const SelectInvoiceScreen({super.key, required this.tenantId});

  @override
  State<SelectInvoiceScreen> createState() => _SelectInvoiceScreenState();
}

class _SelectInvoiceScreenState extends State<SelectInvoiceScreen> {
  final _service = InvoiceService();
  late Future<List<InvoiceModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getInvoicesByTenant(widget.tenantId);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chọn hoá đơn thanh toán',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<InvoiceModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data ?? [];
          final unpaid = all.where((i) => i.status != 'paid').toList();

          if (unpaid.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline,
                        size: 64, color: Colors.green),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tất cả hoá đơn đã được thanh toán!',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green)),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner tổng nợ
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${unpaid.length} hoá đơn chưa thanh toán',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      fmt.format(unpaid.fold(0.0, (s, i) => s + i.totalAmount)),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('Tổng số tiền cần thanh toán',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text('Chọn hoá đơn để thanh toán',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textDark)),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: unpaid.length,
                  itemBuilder: (context, index) {
                    final inv = unpaid[index];
                    final isOverdue = inv.status == 'overdue';
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
                                builder: (_) =>
                                    PaymentDetailScreen(invoice: inv)),
                          );
                          setState(() => _future =
                              _service.getInvoicesByTenant(widget.tenantId));
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            // Badge tháng
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: (isOverdue ? Colors.red : Colors.orange)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(children: [
                                Text('T${inv.month}',
                                    style: TextStyle(
                                        color: isOverdue
                                            ? Colors.red
                                            : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                                Text('${inv.year}',
                                    style: TextStyle(
                                        color: isOverdue
                                            ? Colors.red
                                            : Colors.orange,
                                        fontSize: 10)),
                              ]),
                            ),
                            const SizedBox(width: 16),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Phòng ${inv.roomId}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.textDark)),
                                  const SizedBox(height: 4),
                                  Text(fmt.format(inv.totalAmount),
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary)),
                                  const SizedBox(height: 2),
                                  Text('Điện: ${inv.electricUsed} số',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            // Trạng thái + arrow
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        (isOverdue ? Colors.red : Colors.orange)
                                            .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isOverdue ? 'Quá hạn' : 'Chưa trả',
                                    style: TextStyle(
                                        color: isOverdue
                                            ? Colors.red
                                            : Colors.orange,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.arrow_forward_ios,
                                      color: AppColors.primary, size: 14),
                                ),
                              ],
                            ),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
