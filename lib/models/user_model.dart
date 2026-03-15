import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String phone;
  final String fullName;
  final String? avatarUrl;
  final String role; // admin / tenant
  final String? landlordId;
  final DateTime? dateOfBirth;
  final String? idNumber;
  final String? idFrontUrl;
  final String? idBackUrl;
  final bool isProfileConfirmed;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    this.landlordId,
    this.dateOfBirth,
    this.idNumber,
    this.idFrontUrl,
    this.idBackUrl,
    this.isProfileConfirmed = false,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isTenant => role == 'tenant';

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: d['email'] ?? '',
      phone: d['phone'] ?? '',
      fullName: d['full_name'] ?? '',
      avatarUrl: d['avatar_url'],
      role: d['role'] ?? 'tenant',
      landlordId: d['landlord_id'],
      dateOfBirth: d['date_of_birth'] != null ? (d['date_of_birth'] as Timestamp).toDate() : null,
      idNumber: d['id_number'],
      idFrontUrl: d['id_front_url'],
      idBackUrl: d['id_back_url'],
      isProfileConfirmed: d['is_profile_confirmed'] ?? false,
      fcmToken: d['fcm_token'],
      createdAt: (d['created_at'] as Timestamp).toDate(),
      updatedAt: (d['updated_at'] as Timestamp).toDate(),
    );
  }

  factory UserModel.fromSqlite(Map<String, dynamic> d) {
    return UserModel(
      id: d['id'],
      email: d['email'] ?? '',
      phone: d['phone'] ?? '',
      fullName: d['full_name'] ?? '',
      avatarUrl: d['avatar_url'],
      role: d['role'] ?? 'tenant',
      landlordId: d['landlord_id'],
      dateOfBirth: d['date_of_birth'] != null ? DateTime.parse(d['date_of_birth']) : null,
      idNumber: d['id_number'],
      idFrontUrl: d['id_front_url'],
      idBackUrl: d['id_back_url'],
      isProfileConfirmed: d['is_profile_confirmed'] == 1,
      fcmToken: d['fcm_token'],
      createdAt: DateTime.parse(d['created_at']),
      updatedAt: DateTime.parse(d['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'phone': phone,
    'full_name': fullName,
    'avatar_url': avatarUrl,
    'role': role,
    'landlord_id': landlordId,
    'date_of_birth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
    'id_number': idNumber,
    'id_front_url': idFrontUrl,
    'id_back_url': idBackUrl,
    'is_profile_confirmed': isProfileConfirmed,
    'fcm_token': fcmToken,
    'created_at': Timestamp.fromDate(createdAt),
    'updated_at': Timestamp.fromDate(updatedAt),
  };

  Map<String, dynamic> toSqlite() => {
    'id': id,
    'email': email,
    'phone': phone,
    'full_name': fullName,
    'avatar_url': avatarUrl,
    'role': role,
    'landlord_id': landlordId,
    'date_of_birth': dateOfBirth?.toIso8601String(),
    'id_number': idNumber,
    'id_front_url': idFrontUrl,
    'id_back_url': idBackUrl,
    'is_profile_confirmed': isProfileConfirmed ? 1 : 0,
    'fcm_token': fcmToken,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'is_synced': 1,
  };
}
