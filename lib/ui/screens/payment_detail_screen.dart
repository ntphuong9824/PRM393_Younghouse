import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/invoice_model.dart';
import '../../models/room_model.dart';
import '../../services/invoice_service.dart';
import '../../services/payos_service.dart';

class PaymentDetailScreen extends StatefulWidget {
  final InvoiceModel? invoice;
  const PaymentDetailScreen({super.key, this.invoice});

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  final _payosService = PayosService();
  final _invoiceService = InvoiceService();
  bool _isLoading = false;

  late final InvoiceModel invoice = widget.invoice ??
      InvoiceModel(
        id: 'INV-2024-03',
        room: RoomModel(
          roomId: 'R302',
          roomName: 'Phòng 302',
          baseRent: 1800000,
          waterServicePerPerson: 100000,
          numberOfPeople: 2,
          electricityPricePerUnit: 3000,
        ),
        month: DateTime(2024, 3),
        electricityStart: 1250,
        electricityEnd: 1345,
        isPaid: false,
      );

  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);
    try {
      final orderCode = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _payosService.createPaymentLink(
        orderCode: orderCode,
        amount: invoice.totalAmount.toInt(),
        description:
            'Thanh toan ${invoice.room.roomName} T${invoice.month.month}',
      );
      await _invoiceService.markAsPaid(invoice.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Thanh toán thành công!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi thanh toán: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết hoá đơn',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(children: [
                  Text(invoice.room.roomName,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(
                    'Tháng ${invoice.month.month}/${invoice.month.year}',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: invoice.isPaid
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      invoice.isPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
                      style: TextStyle(
                          color: invoice.isPaid ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 30),

              // Bảng chi tiết
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    _row('Tiền phòng cố định',
                        fmt.format(invoice.room.baseRent)),
                    const Divider(height: 30),
                    _row(
                      'Nước & Dịch vụ',
                      fmt.format(invoice.room.totalWaterService),
                      sub:
                          '(${invoice.room.numberOfPeople} người x ${fmt.format(invoice.room.waterServicePerPerson)})',
                    ),
                    const Divider(height: 30),
                    _row(
                      'Tiền điện',
                      fmt.format(invoice.electricityCost),
                      sub:
                          '(${invoice.electricityUsed.toInt()} số x ${fmt.format(invoice.room.electricityPricePerUnit)})',
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Chỉ số: ${invoice.electricityStart.toInt()} → ${invoice.electricityEnd.toInt()}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                    const Divider(height: 40, thickness: 1.5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TỔNG CỘNG',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(fmt.format(invoice.totalAmount),
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                      ],
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 30),
              const Text('Hướng dẫn thanh toán',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                ),
                child: const Column(children: [
                  _InfoRow(Icons.account_balance, 'Ngân hàng: MB Bank'),
                  SizedBox(height: 8),
                  _InfoRow(Icons.person, 'Chủ TK: YOUNG HOUSE ADMIN'),
                  SizedBox(height: 8),
                  _InfoRow(Icons.numbers, 'STK: 0123456789'),
                  SizedBox(height: 8),
                  _InfoRow(
                      Icons.info_outline, 'Nội dung: [Phòng] T[Tháng]/[Năm]'),
                ]),
              ),

              const SizedBox(height: 40),
              if (!invoice.isPaid)
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
              const SizedBox(height: 20),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.1),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ]),
    );
  }

  Widget _row(String title, String amount, {String? sub}) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
                if (sub != null) ...[
                  const SizedBox(height: 4),
                  Text(sub,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: Colors.blue),
      const SizedBox(width: 12),
      Text(text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    ]);
  }
}
