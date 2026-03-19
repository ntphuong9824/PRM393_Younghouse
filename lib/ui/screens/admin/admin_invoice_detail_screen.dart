import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/invoice_model.dart';
import '../../../services/invoice_service.dart';

class AdminInvoiceDetailScreen extends StatefulWidget {
  final InvoiceModel invoice;
  final String landlordId;

  const AdminInvoiceDetailScreen({
    super.key,
    required this.invoice,
    required this.landlordId,
  });

  @override
  State<AdminInvoiceDetailScreen> createState() =>
      _AdminInvoiceDetailScreenState();
}

class _AdminInvoiceDetailScreenState extends State<AdminInvoiceDetailScreen> {
  final _service = InvoiceService();
  final _fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  bool _isMarking = false;

  Future<void> _markAsPaid() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: const Text('Đánh dấu hoá đơn này là đã thanh toán?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isMarking = true);
    try {
      await _service.markAsPaid(widget.invoice.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đã đánh dấu thanh toán'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isMarking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final isPaid = inv.status == 'paid';
    final isOverdue = inv.status == 'overdue';

    final statusColor =
        isPaid ? Colors.green : (isOverdue ? Colors.red : Colors.orange);
    final statusLabel =
        isPaid ? 'Đã thanh toán' : (isOverdue ? 'Quá hạn' : 'Chưa thanh toán');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Hoá đơn T${inv.month}/${inv.year}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tháng ${inv.month}/${inv.year}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(statusLabel,
                              style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _row('Phòng', inv.roomId),
                    _row('Tenant ID', inv.tenantId),
                    _row('Hạn thanh toán',
                        DateFormat('dd/MM/yyyy').format(inv.dueDate)),
                    if (inv.paidAt != null)
                      _row('Thanh toán lúc',
                          DateFormat('dd/MM/yyyy HH:mm').format(inv.paidAt!)),
                    if (inv.paymentMethod != null)
                      _row('Phương thức', inv.paymentMethod!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Chi tiết tiền
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _billRow('Tiền phòng', inv.rentAmount),
                    const Divider(height: 24),
                    _billRow(
                      'Tiền điện',
                      inv.electricCost,
                      subtitle: inv.electricUsed > 0
                          ? '${inv.electricUsed} số × ${_fmt.format(inv.electricPrice)}\n${inv.electricPrev} → ${inv.electricCurr}'
                          : null,
                    ),
                    if (inv.waterUsed > 0) ...[
                      const Divider(height: 24),
                      _billRow(
                        'Tiền nước',
                        inv.waterCost,
                        subtitle:
                            '${inv.waterUsed} m³ × ${_fmt.format(inv.waterPrice)}\n${inv.waterPrev} → ${inv.waterCurr}',
                      ),
                    ],
                    if (inv.otherFees > 0) ...[
                      const Divider(height: 24),
                      _billRow('Phí khác', inv.otherFees),
                    ],
                    const Divider(height: 24, thickness: 1.5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TỔNG CỘNG',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(_fmt.format(inv.totalAmount),
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (inv.notes != null && inv.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.note_outlined, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(child: Text(inv.notes!)),
                    ],
                  ),
                ),
              ),
            ],

            if (!isPaid) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isMarking ? null : _markAsPaid,
                  icon: const Icon(Icons.check_circle_outline),
                  label: _isMarking
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ĐÁNH DẤU ĐÃ THANH TOÁN',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );

  Widget _billRow(String label, double amount, {String? subtitle}) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ],
            ),
          ),
          Text(_fmt.format(amount),
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      );
}
