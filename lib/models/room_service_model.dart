import 'package:cloud_firestore/cloud_firestore.dart';

class RoomServiceModel {
  final String id;
  final String roomId;
  final String serviceName;
  final String unit; // kWh, person, month
  final double pricePerUnit;
  final bool isMetered;
  final DateTime createdAt;
  final DateTime updatedAt;

  RoomServiceModel({
    required this.id,
    required this.roomId,
    required this.serviceName,
    required this.unit,
    required this.pricePerUnit,
    this.isMetered = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoomServiceModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RoomServiceModel(
      id: doc.id,
      roomId: d['room_id'] ?? '',
      serviceName: d['service_name'] ?? '',
      unit: d['unit'] ?? '',
      pricePerUnit: (d['price_per_unit'] ?? 0).toDouble(),
      isMetered: d['is_metered'] ?? false,
      createdAt: (d['created_at'] as Timestamp).toDate(),
      updatedAt: (d['updated_at'] as Timestamp).toDate(),
    );
  }

  factory RoomServiceModel.fromSqlite(Map<String, dynamic> d) {
    return RoomServiceModel(
      id: d['id'],
      roomId: d['room_id'] ?? '',
      serviceName: d['service_name'] ?? '',
      unit: d['unit'] ?? '',
      pricePerUnit: d['price_per_unit'] ?? 0.0,
      isMetered: d['is_metered'] == 1,
      createdAt: DateTime.parse(d['created_at']),
      updatedAt: DateTime.parse(d['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'room_id': roomId,
    'service_name': serviceName,
    'unit': unit,
    'price_per_unit': pricePerUnit,
    'is_metered': isMetered,
    'created_at': Timestamp.fromDate(createdAt),
    'updated_at': Timestamp.fromDate(updatedAt),
  };

  Map<String, dynamic> toSqlite() => {
    'id': id,
    'room_id': roomId,
    'service_name': serviceName,
    'unit': unit,
    'price_per_unit': pricePerUnit,
    'is_metered': isMetered ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'is_synced': 1,
  };
}
