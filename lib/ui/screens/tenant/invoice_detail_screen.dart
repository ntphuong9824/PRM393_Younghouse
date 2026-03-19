import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/invoice_model.dart';
import '../../../services/payos_service.dart';

class PaymentDetailScreen extends StatefulWidget {
  final InvoiceModel invoice;
  const PaymentDetailScreen({super.key, required this.invoice});

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  final PayosService _payosService = PayosService();
  bool _isLoading = false;

  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);
    try {
      await _payosService.createPaymentLink(
        orderCode: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        amount: widget.invoice.totalAmount.toInt(),
        description:
            'Thanh toan phong T${widget.invoice.month}/${widget.invoice.year}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thanh toán: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final inv = widget.invoice;
    final isPaid = inv.status == 'paid';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết thanh toán',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Tháng ${inv.month}/${inv.year}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
                          style: TextStyle(
                              color: isPaid ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Billing Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _billRow('Tiền phòng', fmt.format(inv.rentAmount)),
                        const Divider(height: 30),
                        _billRow(
                          'Tiền điện',
                          fmt.format(inv.electricCost),
                          subtitle:
                              '(${inv.electricUsed} số x ${fmt.format(inv.electricPrice)})\n'
                              'Chỉ số: ${inv.electricPrev} → ${inv.electricCurr}',
                        ),
                        if (inv.waterUsed > 0) ...[
                          const Divider(height: 30),
                          _billRow(
                            'Tiền nước',
                            fmt.format(inv.waterCost),
                            subtitle:
                                '(${inv.waterUsed} m³ x ${fmt.format(inv.waterPrice)})\n'
                                'Chỉ số: ${inv.waterPrev} → ${inv.waterCurr}',
                          ),
                        ],
                        if (inv.otherFees > 0) ...[
                          const Divider(height: 30),
                          _billRow('Phí khác', fmt.format(inv.otherFees)),
                        ],
                        const Divider(height: 40, thickness: 1.5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TỔNG CỘNG',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            Text(
                              fmt.format(inv.totalAmount),
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                        if (inv.paidAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Đã thanh toán lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(inv.paidAt!)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.green),
                          ),
                        ],
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
                          const Icon(Icons.note_outlined,
                              color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(child: Text(inv.notes!)),
                        ],
                      ),
                    ),
                  ),
                ],

                if (!isPaid) ...[
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handlePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('THANH TOÁN NGAY',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _billRow(String title, String amount, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ],
          ),
        ),
        Text(amount,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
