import 'package:cloud_firestore/cloud_firestore.dart';

class GuardianModel {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String relationship; // bố, mẹ, anh, chị...

  GuardianModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.relationship,
  });

  factory GuardianModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return GuardianModel(
      id: doc.id,
      userId: d['user_id'] ?? '',
      fullName: d['full_name'] ?? '',
      phone: d['phone'] ?? '',
      relationship: d['relationship'] ?? '',
    );
  }

  factory GuardianModel.fromSqlite(Map<String, dynamic> d) {
    return GuardianModel(
      id: d['id'],
      userId: d['user_id'] ?? '',
      fullName: d['full_name'] ?? '',
      phone: d['phone'] ?? '',
      relationship: d['relationship'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'user_id': userId,
    'full_name': fullName,
    'phone': phone,
    'relationship': relationship,
  };

  Map<String, dynamic> toSqlite() => {
    'id': id,
    'user_id': userId,
    'full_name': fullName,
    'phone': phone,
    'relationship': relationship,
  };
}
