import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/room_model.dart';
import '../../models/invoice_model.dart';
import 'payment_detail_screen.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu mẫu lịch sử thanh toán
    final room = RoomModel(
      roomId: "R302",
      roomName: "Phòng 302",
      baseRent: 1800000,
      waterServicePerPerson: 100000,
      numberOfPeople: 2,
      electricityPricePerUnit: 3000,
    );

    final List<InvoiceModel> history = [
      InvoiceModel(
        id: "INV-03-24",
        room: room,
        month: DateTime(2024, 3),
        electricityStart: 1250,
        electricityEnd: 1345,
        isPaid: false, // Tháng hiện tại chưa trả
      ),
      InvoiceModel(
        id: "INV-02-24",
        room: room,
        month: DateTime(2024, 2),
        electricityStart: 1150,
        electricityEnd: 1250,
        isPaid: true,
      ),
      InvoiceModel(
        id: "INV-01-24",
        room: room,
        month: DateTime(2024, 1),
        electricityStart: 1040,
        electricityEnd: 1150,
        isPaid: true,
      ),
      InvoiceModel(
        id: "INV-12-23",
        room: room,
        month: DateTime(2023, 12),
        electricityStart: 950,
        electricityEnd: 1040,
        isPaid: true,
      ),
    ];

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Lịch sử thanh toán", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final invoice = history[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: () {
                // Chuyển sang chi tiết khi nhấn vào card
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PaymentDetailScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Cột tháng
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "T${invoice.month.month}",
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            "${invoice.month.year}",
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Cột thông tin tiền
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currencyFormat.format(invoice.totalAmount),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Điện: ${invoice.electricityUsed.toInt()} số",
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    
                    // Cột trạng thái
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: invoice.isPaid 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            invoice.isPaid ? "Đã trả" : "Chưa trả",
                            style: TextStyle(
                              color: invoice.isPaid ? Colors.green : Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
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
