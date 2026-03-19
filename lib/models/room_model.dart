import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
  final String propertyId;
  final String? currentTenantId;
  final String? currentContractId;
  final String roomNumber;
  final int floor;
  final double areaSqm;
  final double basePrice;
  final double depositAmount;
  final String? description;
  final List<String> images;
  final String status; // vacant / occupied / maintenance
  final DateTime createdAt;
  final DateTime updatedAt;

  RoomModel({
    required this.id,
    required this.propertyId,
    this.currentTenantId,
    this.currentContractId,
    required this.roomNumber,
    this.floor = 1,
    this.areaSqm = 0,
    required this.basePrice,
    this.depositAmount = 0,
    this.description,
    this.images = const [],
    this.status = 'vacant',
    required this.createdAt,
    required this.updatedAt,
  });

  RoomModel copyWith({
    String? id,
    String? propertyId,
    String? currentTenantId,
    String? currentContractId,
    String? roomNumber,
    int? floor,
    double? areaSqm,
    double? basePrice,
    double? depositAmount,
    String? description,
    List<String>? images,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      currentTenantId: currentTenantId ?? this.currentTenantId,
      currentContractId: currentContractId ?? this.currentContractId,
      roomNumber: roomNumber ?? this.roomNumber,
      floor: floor ?? this.floor,
      areaSqm: areaSqm ?? this.areaSqm,
      basePrice: basePrice ?? this.basePrice,
      depositAmount: depositAmount ?? this.depositAmount,
      description: description ?? this.description,
      images: images ?? this.images,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RoomModel(
      id: doc.id,
      propertyId: d['property_id'] ?? '',
      currentTenantId: d['current_tenant_id'],
      currentContractId: d['current_contract_id'],
      roomNumber: d['room_number'] ?? '',
      floor: d['floor'] ?? 1,
      areaSqm: (d['area_sqm'] ?? 0).toDouble(),
      basePrice: (d['base_price'] ?? 0).toDouble(),
      depositAmount: (d['deposit_amount'] ?? 0).toDouble(),
      description: d['description'],
      images: List<String>.from(d['images'] ?? []),
      status: d['status'] ?? 'vacant',
      createdAt: (d['created_at'] as Timestamp).toDate(),
      updatedAt: (d['updated_at'] as Timestamp).toDate(),
    );
  }

  factory RoomModel.fromSqlite(Map<String, dynamic> d) {
    final rawImages = d['images'];
    List<String> images = const [];
    if (rawImages is String && rawImages.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawImages);
        if (decoded is List) {
          images = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        // Backward compatibility for old comma-separated format.
        images = rawImages.split(',').where((e) => e.isNotEmpty).toList();
      }
    }

    return RoomModel(
      id: d['id'],
      propertyId: d['property_id'] ?? '',
      currentTenantId: d['current_tenant_id'],
      currentContractId: d['current_contract_id'],
      roomNumber: d['room_number'] ?? '',
      floor: d['floor'] ?? 1,
      areaSqm: d['area_sqm'] ?? 0.0,
      basePrice: d['base_price'] ?? 0.0,
      depositAmount: d['deposit_amount'] ?? 0.0,
      description: d['description'],
      images: images,
      status: d['status'] ?? 'vacant',
      createdAt: DateTime.parse(d['created_at']),
      updatedAt: DateTime.parse(d['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'property_id': propertyId,
    'current_tenant_id': currentTenantId,
    'current_contract_id': currentContractId,
    'room_number': roomNumber,
    'floor': floor,
    'area_sqm': areaSqm,
    'base_price': basePrice,
    'deposit_amount': depositAmount,
    'description': description,
    'images': images,
    'status': status,
    'created_at': Timestamp.fromDate(createdAt),
    'updated_at': Timestamp.fromDate(updatedAt),
  };

  Map<String, dynamic> toSqlite() => {
    'id': id,
    'property_id': propertyId,
    'current_tenant_id': currentTenantId,
    'current_contract_id': currentContractId,
    'room_number': roomNumber,
    'floor': floor,
    'area_sqm': areaSqm,
    'base_price': basePrice,
    'deposit_amount': depositAmount,
    'description': description,
    'images': jsonEncode(images),
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'is_synced': 1,
  };
}
