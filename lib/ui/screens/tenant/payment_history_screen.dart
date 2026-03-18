import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/invoice_model.dart';
import '../../../services/local_db_service.dart';
import 'payment_detail_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String tenantId;
  const PaymentHistoryScreen({super.key, required this.tenantId});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final _db = LocalDbService();
  List<InvoiceModel> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final rows = await _db.getAll(
      'invoices',
      where: 'tenant_id = ?',
      whereArgs: [widget.tenantId],
      orderBy: 'year DESC, month DESC',
    );
    setState(() {
      _invoices = rows.map((r) => InvoiceModel.fromSqlite(r)).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Lịch sử thanh toán",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
              ? const Center(
                  child: Text("Chưa có hóa đơn nào",
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _invoices.length,
                  itemBuilder: (context, index) {
                    final inv = _invoices[index];
                    final isPaid = inv.status == 'paid';
                    final isOverdue = inv.status == 'overdue';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PaymentDetailScreen(invoice: inv),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text("T${inv.month}",
                                        style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18)),
                                    Text("${inv.year}",
                                        style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 10)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(fmt.format(inv.totalAmount),
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textDark)),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Điện: ${inv.electricUsed} số",
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPaid
                                          ? Colors.green
                                              .withValues(alpha: 0.1)
                                          : isOverdue
                                              ? Colors.red
                                                  .withValues(alpha: 0.1)
                                              : Colors.orange
                                                  .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isPaid
                                          ? "Đã trả"
                                          : isOverdue
                                              ? "Quá hạn"
                                              : "Chưa trả",
                                      style: TextStyle(
                                          color: isPaid
                                              ? Colors.green
                                              : isOverdue
                                                  ? Colors.red
                                                  : Colors.orange,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Icon(Icons.chevron_right,
                                      color: Colors.grey, size: 20),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
