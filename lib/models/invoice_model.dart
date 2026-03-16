import 'room_model.dart';

class InvoiceModel {
  final String id;
  final RoomModel room;
  final DateTime month;
  final double electricityStart;
  final double electricityEnd;
  final bool isPaid;
  final DateTime? createdAt;

  InvoiceModel({
    required this.id,
    required this.room,
    required this.month,
    required this.electricityStart,
    required this.electricityEnd,
    this.isPaid = false,
    this.createdAt,
  });

  double get electricityUsed => electricityEnd - electricityStart;
  double get electricityCost => electricityUsed * room.electricityPricePerUnit;
  double get totalAmount =>
      room.baseRent + room.totalWaterService + electricityCost;

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'roomId': room.roomId,
        'roomName': room.roomName,
        'baseRent': room.baseRent,
        'waterServicePerPerson': room.waterServicePerPerson,
        'numberOfPeople': room.numberOfPeople,
        'electricityPricePerUnit': room.electricityPricePerUnit,
        'month': month.toIso8601String(),
        'electricityStart': electricityStart,
        'electricityEnd': electricityEnd,
        'isPaid': isPaid,
        'totalAmount': totalAmount,
        'createdAt':
            createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };

  factory InvoiceModel.fromFirestore(Map<String, dynamic> data) {
    final room = RoomModel(
      roomId: data['roomId'] ?? '',
      roomName: data['roomName'] ?? '',
      baseRent: (data['baseRent'] ?? 0).toDouble(),
      waterServicePerPerson: (data['waterServicePerPerson'] ?? 0).toDouble(),
      numberOfPeople: (data['numberOfPeople'] ?? 1).toInt(),
      electricityPricePerUnit:
          (data['electricityPricePerUnit'] ?? 0).toDouble(),
    );
    return InvoiceModel(
      id: data['id'] ?? '',
      room: room,
      month: DateTime.parse(data['month']),
      electricityStart: (data['electricityStart'] ?? 0).toDouble(),
      electricityEnd: (data['electricityEnd'] ?? 0).toDouble(),
      isPaid: data['isPaid'] ?? false,
      createdAt:
          data['createdAt'] != null ? DateTime.parse(data['createdAt']) : null,
    );
  }
}
