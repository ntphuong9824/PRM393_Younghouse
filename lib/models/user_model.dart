import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String phone;
  final String fullName;
  final String? avatarUrl;
  final String role; // 'admin' | 'tenant'
  final String? landlordId;
  final DateTime? dateOfBirth;
  final String? idNumber;
  final String? idFrontUrl;
  final String? idBackUrl;
  final bool isProfileConfirmed;
  final String? fcmToken;
  final String? guardianName;
  final String? guardianPhone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.guardianName,
    this.guardianPhone,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      fullName: data['full_name'] ?? '',
      avatarUrl: data['avatar_url'],
      role: data['role'] ?? 'tenant',
      landlordId: data['landlord_id'],
      dateOfBirth: (data['date_of_birth'] as Timestamp?)?.toDate(),
      idNumber: data['id_number'],
      idFrontUrl: data['id_front_url'],
      idBackUrl: data['id_back_url'],
      isProfileConfirmed: data['is_profile_confirmed'] ?? false,
      fcmToken: data['fcm_token'],
      guardianName: data['guardian_name'],
      guardianPhone: data['guardian_phone'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'phone': phone,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'role': role,
      'landlord_id': landlordId,
      'date_of_birth':
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'id_number': idNumber,
      'id_front_url': idFrontUrl,
      'id_back_url': idBackUrl,
      'is_profile_confirmed': isProfileConfirmed,
      'fcm_token': fcmToken,
      'guardian_name': guardianName,
      'guardian_phone': guardianPhone,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? idNumber,
    String? idFrontUrl,
    String? idBackUrl,
    bool? isProfileConfirmed,
    String? fcmToken,
    String? guardianName,
    String? guardianPhone,
  }) {
    return UserModel(
      id: id,
      email: email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role,
      landlordId: landlordId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      idNumber: idNumber ?? this.idNumber,
      idFrontUrl: idFrontUrl ?? this.idFrontUrl,
      idBackUrl: idBackUrl ?? this.idBackUrl,
      isProfileConfirmed: isProfileConfirmed ?? this.isProfileConfirmed,
      fcmToken: fcmToken ?? this.fcmToken,
      guardianName: guardianName ?? this.guardianName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
