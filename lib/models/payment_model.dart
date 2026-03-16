import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String invoiceId;
  final String tenantId;
  final String landlordId;
  final double amount;
  final String method; // cash / transfer / payos
  final String? note;
  final String? receiptUrl;
  final DateTime paidAt;
  final String createdBy;

  PaymentModel({
    required this.id,
    required this.invoiceId,
    required this.tenantId,
    required this.landlordId,
    required this.amount,
    required this.method,
    this.note,
    this.receiptUrl,
    required this.paidAt,
    required this.createdBy,
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      invoiceId: d['invoice_id'] ?? '',
      tenantId: d['tenant_id'] ?? '',
      landlordId: d['landlord_id'] ?? '',
      amount: (d['amount'] ?? 0).toDouble(),
      method: d['method'] ?? 'cash',
      note: d['note'],
      receiptUrl: d['receipt_url'],
      paidAt: (d['paid_at'] as Timestamp).toDate(),
      createdBy: d['created_by'] ?? '',
    );
  }

  factory PaymentModel.fromSqlite(Map<String, dynamic> d) {
    return PaymentModel(
      id: d['id'],
      invoiceId: d['invoice_id'] ?? '',
      tenantId: d['tenant_id'] ?? '',
      landlordId: d['landlord_id'] ?? '',
      amount: d['amount'] ?? 0.0,
      method: d['method'] ?? 'cash',
      note: d['note'],
      receiptUrl: d['receipt_url'],
      paidAt: DateTime.parse(d['paid_at']),
      createdBy: d['created_by'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'invoice_id': invoiceId,
    'tenant_id': tenantId,
    'landlord_id': landlordId,
    'amount': amount,
    'method': method,
    'note': note,
    'receipt_url': receiptUrl,
    'paid_at': Timestamp.fromDate(paidAt),
    'created_by': createdBy,
  };

  Map<String, dynamic> toSqlite() => {
    'id': id,
    'invoice_id': invoiceId,
    'tenant_id': tenantId,
    'landlord_id': landlordId,
    'amount': amount,
    'method': method,
    'note': note,
    'receipt_url': receiptUrl,
    'paid_at': paidAt.toIso8601String(),
    'created_by': createdBy,
    'is_synced': 1,
  };
}
