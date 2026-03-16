import 'package:cloud_firestore/cloud_firestore.dart';

class ContractModel {
  final String id;
  final String roomId;
  final String tenantId;
  final String landlordId;
  final DateTime startDate;
  final DateTime endDate;
  final double monthlyRent;
  final double deposit;
  final List<String> coTenants;
  final String? terms;
  final String status; // active / expired / terminated
  final String? pdfUrl;
  final DateTime? signedAt;
  final DateTime? terminatedAt;
  final String? terminationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContractModel({
    required this.id,
    required this.roomId,
    required this.tenantId,
    required this.landlordId,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.deposit,
    this.coTenants = const [],
    this.terms,
    this.status = 'active',
    this.pdfUrl,
    this.signedAt,
    this.terminatedAt,
    this.terminationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContractModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ContractModel(
      id: doc.id,
      roomId: d['room_id'] ?? '',
      tenantId: d['tenant_id'] ?? '',
      landlordId: d['landlord_id'] ?? '',
      startDate: (d['start_date'] as Timestamp).toDate(),
      endDate: (d['end_date'] as Timestamp).toDate(),
      monthlyRent: (d['monthly_rent'] ?? 0).toDouble(),
      deposit: (d['deposit'] ?? 0).toDouble(),
      coTenants: List<String>.from(d['co_tenants'] ?? []),
      terms: d['terms'],
      status: d['status'] ?? 'active',
      pdfUrl: d['pdf_url'],
      signedAt: d['signed_at'] != null ? (d['signed_at'] as Timestamp).toDate() : null,
      terminatedAt: d['terminated_at'] != null ? (d['terminated_at'] as Timestamp).toDate() : null,
      terminationReason: d['termination_reason'],
      createdAt: (d['created_at'] as Timestamp).toDate(),
      updatedAt: (d['updated_at'] as Timestamp).toDate(),
    );
  }

  factory ContractModel.fromSqlite(Map<String, dynamic> d) {
    return ContractModel(
      id: d['id'],
      roomId: d['room_id'] ?? '',
      tenantId: d['tenant_id'] ?? '',
      landlordId: d['landlord_id'] ?? '',
      startDate: DateTime.parse(d['start_date']),
      endDate: DateTime.parse(d['end_date']),
      monthlyRent: d['monthly_rent'] ?? 0.0,
      deposit: d['deposit'] ?? 0.0,
      coTenants: d['co_tenants'] != null ? (d['co_tenants'] as String).split(',').where((e) => e.isNotEmpty).toList() : [],
      terms: d['terms'],
      status: d['status'] ?? 'active',
      pdfUrl: d['pdf_url'],
      signedAt: d['signed_at'] != null ? DateTime.parse(d['signed_at']) : null,
      terminatedAt: d['terminated_at'] != null ? DateTime.parse(d['terminated_at']) : null,
      terminationReason: d['termination_reason'],
      createdAt: DateTime.parse(d['created_at']),
      updatedAt: DateTime.parse(d['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'room_id': roomId,
    'tenant_id': tenantId,
    'landlord_id': landlordId,
    'start_date': Timestamp.fromDate(startDate),
    'end_date': Timestamp.fromDate(endDate),
    'monthly_rent': monthlyRent,
    'deposit': deposit,
    'co_tenants': coTenants,
    'terms': terms,
    'status': status,
    'pdf_url': pdfUrl,
    'signed_at': signedAt != null ? Timestamp.fromDate(signedAt!) : null,
    'terminated_at': terminatedAt != null ? Timestamp.fromDate(terminatedAt!) : null,
    'termination_reason': terminationReason,
    'created_at': Timestamp.fromDate(createdAt),
    'updated_at': Timestamp.fromDate(updatedAt),
  };

  Map<String, dynamic> toSqlite() => {
    'id': id,
    'room_id': roomId,
    'tenant_id': tenantId,
    'landlord_id': landlordId,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'monthly_rent': monthlyRent,
    'deposit': deposit,
    'co_tenants': coTenants.join(','),
    'terms': terms,
    'status': status,
    'pdf_url': pdfUrl,
    'signed_at': signedAt?.toIso8601String(),
    'terminated_at': terminatedAt?.toIso8601String(),
    'termination_reason': terminationReason,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'is_synced': 1,
  };
}
