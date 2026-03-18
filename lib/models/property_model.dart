import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyModel {
  final String id;
  final String landlordId;
  final String name;
  final String address;
  final String ward;
  final String district;
  final String city;
  final String? description;
  final int totalRooms;
  final String status; // active / inactive
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  PropertyModel({
    required this.id,
    required this.landlordId,
    required this.name,
    required this.address,
    required this.ward,
    required this.district,
    required this.city,
    this.description,
    this.totalRooms = 0,
    this.status = 'active',
    this.images = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullAddress => '$address, $ward, $district, $city';

  PropertyModel copyWith({
    String? id,
    String? landlordId,
    String? name,
    String? address,
    String? ward,
    String? district,
    String? city,
    String? description,
    int? totalRooms,
    String? status,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      landlordId: landlordId ?? this.landlordId,
      name: name ?? this.name,
      address: address ?? this.address,
      ward: ward ?? this.ward,
      district: district ?? this.district,
      city: city ?? this.city,
      description: description ?? this.description,
      totalRooms: totalRooms ?? this.totalRooms,
      status: status ?? this.status,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PropertyModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PropertyModel(
      id: doc.id,
      landlordId: d['landlord_id'] ?? '',
      name: d['name'] ?? '',
      address: d['address'] ?? '',
      ward: d['ward'] ?? '',
      district: d['district'] ?? '',
      city: d['city'] ?? '',
      description: d['description'],
      totalRooms: d['total_rooms'] ?? 0,
      status: d['status'] ?? 'active',
      images: List<String>.from(d['images'] ?? []),
      createdAt: (d['created_at'] as Timestamp).toDate(),
      updatedAt: (d['updated_at'] as Timestamp).toDate(),
    );
  }

  factory PropertyModel.fromSqlite(Map<String, dynamic> d) {
    return PropertyModel(
      id: d['id'],
      landlordId: d['landlord_id'] ?? '',
      name: d['name'] ?? '',
      address: d['address'] ?? '',
      ward: d['ward'] ?? '',
      district: d['district'] ?? '',
      city: d['city'] ?? '',
      description: d['description'],
      totalRooms: d['total_rooms'] ?? 0,
      status: d['status'] ?? 'active',
      images: d['images'] != null ? (d['images'] as String).split(',').where((e) => e.isNotEmpty).toList() : [],
      createdAt: DateTime.parse(d['created_at']),
      updatedAt: DateTime.parse(d['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'landlord_id': landlordId,
    'name': name,
    'address': address,
    'ward': ward,
    'district': district,
    'city': city,
    'description': description,
    'total_rooms': totalRooms,
    'status': status,
    'images': images,
    'created_at': Timestamp.fromDate(createdAt),
    'updated_at': Timestamp.fromDate(updatedAt),
  };

  Map<String, dynamic> toSqlite() => {
    'id': id,
    'landlord_id': landlordId,
    'name': name,
    'address': address,
    'ward': ward,
    'district': district,
    'city': city,
    'description': description,
    'total_rooms': totalRooms,
    'status': status,
    'images': images.join(','),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'is_synced': 1,
  };
}
