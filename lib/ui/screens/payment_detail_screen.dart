import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/room_model.dart';
import '../../models/invoice_model.dart';
import 'package:intl/intl.dart';

class PaymentDetailScreen extends StatelessWidget {
  const PaymentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu giả định (Sau này sẽ lấy từ API/Admin set)
    final room = RoomModel(
      roomId: "R302",
      roomName: "Phòng 302",
      baseRent: 1800000,
      waterServicePerPerson: 100000,
      numberOfPeople: 2,
      electricityPricePerUnit: 3000,
    );

    final invoice = InvoiceModel(
      id: "INV-2024-03",
      room: room,
      month: DateTime(2024, 3),
      electricityStart: 1250,
      electricityEnd: 1345,
      isPaid: false,
    );

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Chi tiết thanh toán", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Header
            Center(
              child: Column(
                children: [
                  Text(
                    "Tháng ${invoice.month.month}/${invoice.month.year}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Chưa thanh toán",
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Billing Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildBillRow("Tiền phòng cố định", currencyFormat.format(room.baseRent)),
                    const Divider(height: 30),
                    _buildBillRow(
                      "Nước & Dịch vụ",
                      currencyFormat.format(room.totalWaterService),
                      subtitle: "(${room.numberOfPeople} người x ${currencyFormat.format(room.waterServicePerPerson)})",
                    ),
                    const Divider(height: 30),
                    _buildBillRow(
                      "Tiền điện",
                      currencyFormat.format(invoice.electricityCost),
                      subtitle: "(${invoice.electricityUsed.toInt()} số x ${currencyFormat.format(room.electricityPricePerUnit)})",
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Chỉ số: ${invoice.electricityStart.toInt()} -> ${invoice.electricityEnd.toInt()}",
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                    const Divider(height: 40, thickness: 1.5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "TỔNG CỘNG",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          currencyFormat.format(invoice.totalAmount),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            const Text(
              "Hướng dẫn thanh toán",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
              ),
              child: const Column(
                children: [
                  _buildInfoRow(Icons.account_balance, "Ngân hàng: MB Bank"),
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.person, "Chủ TK: YOUNG HOUSE ADMIN"),
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.numbers, "STK: 0123456789"),
                  SizedBox(height: 8),
                  _buildInfoRow(Icons.info_outline, "Nội dung: P302 T3/2024"),
                ],
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Logic mở app ngân hàng hoặc quét QR
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("THANH TOÁN NGAY", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBillRow(String title, String amount, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ],
          ),
        ),
        Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _buildInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _buildInfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
