import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/invoice_model.dart';
import '../../models/room_model.dart';
import '../../services/invoice_service.dart';
import 'payment_detail_screen.dart';

// Dữ liệu mẫu dùng khi Firestore chưa sẵn sàng
final _sampleRoom = RoomModel(
  roomId: 'R302',
  roomName: 'Phòng 302',
  baseRent: 1800000,
  waterServicePerPerson: 100000,
  numberOfPeople: 2,
  electricityPricePerUnit: 3000,
);

final _sampleInvoices = [
  InvoiceModel(
      id: 'INV-R302-03-2024',
      room: _sampleRoom,
      month: DateTime(2024, 3),
      electricityStart: 1250,
      electricityEnd: 1345,
      isPaid: false),
  InvoiceModel(
      id: 'INV-R302-02-2024',
      room: _sampleRoom,
      month: DateTime(2024, 2),
      electricityStart: 1150,
      electricityEnd: 1250,
      isPaid: true),
  InvoiceModel(
      id: 'INV-R302-01-2024',
      room: _sampleRoom,
      month: DateTime(2024, 1),
      electricityStart: 1040,
      electricityEnd: 1150,
      isPaid: true),
  InvoiceModel(
      id: 'INV-R302-12-2023',
      room: _sampleRoom,
      month: DateTime(2023, 12),
      electricityStart: 950,
      electricityEnd: 1040,
      isPaid: true),
];

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final invoiceService = InvoiceService();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch sử hoá đơn',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<InvoiceModel>>(
        stream: invoiceService.getAllInvoices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Firestore lỗi (vd: permission-denied) → hiển thị dữ liệu mẫu
            return _buildList(context, _sampleInvoices, currencyFormat,
                isSample: true);
          }

          final invoices = snapshot.data ?? [];
          if (invoices.isEmpty) {
            return _buildList(context, _sampleInvoices, currencyFormat,
                isSample: true);
          }
          return _buildList(context, invoices, currencyFormat);
        },
      ),
    );
  }

  Widget _buildList(
      BuildContext context, List<InvoiceModel> invoices, NumberFormat fmt,
      {bool isSample = false}) {
    return Column(
      children: [
        if (isSample)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange.withValues(alpha: 0.1),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Text('Đang hiển thị dữ liệu mẫu',
                    style: TextStyle(color: Colors.orange, fontSize: 13)),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PaymentDetailScreen(invoice: invoice)),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Badge tháng
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text('T${invoice.month.month}',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                              Text('${invoice.month.year}',
                                  style: const TextStyle(
                                      color: AppColors.primary, fontSize: 10)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Thông tin
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(invoice.room.roomName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textDark)),
                              const SizedBox(height: 2),
                              Text(fmt.format(invoice.totalAmount),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark)),
                              const SizedBox(height: 4),
                              Text(
                                  'Điện: ${invoice.electricityUsed.toInt()} số',
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
                                color: invoice.isPaid
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                invoice.isPaid ? 'Đã trả' : 'Chưa trả',
                                style: TextStyle(
                                    color: invoice.isPaid
                                        ? Colors.green
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
        ),
      ],
    );
  }
}
