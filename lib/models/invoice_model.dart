import 'room_model.dart';

class InvoiceModel {
  final String id;
  final RoomModel room;
  final DateTime month;
  final double electricityStart; // Chỉ số điện đầu
  final double electricityEnd;   // Chỉ số điện cuối
  final bool isPaid;

  InvoiceModel({
    required this.id,
    required this.room,
    required this.month,
    required this.electricityStart,
    required this.electricityEnd,
    this.isPaid = false,
  });

  double get electricityUsed => electricityEnd - electricityStart;
  double get electricityCost => electricityUsed * room.electricityPricePerUnit;
  double get totalAmount => room.baseRent + room.totalWaterService + electricityCost;
}
