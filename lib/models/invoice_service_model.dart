import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceServiceModel {
  final String id;
  final String invoiceId;
  final String serviceName;
  final double quantity;
  final double unitPrice;
  final double amount;
  final String? note;

  InvoiceServiceModel({
    required this.id,
    required this.invoiceId,
    required this.serviceName,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    this.note,
  });

  factory InvoiceServiceModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return InvoiceServiceModel(
      id: doc.id,
      invoiceId: d['invoice_id'] ?? '',
      serviceName: d['service_name'] ?? '',
      quantity: (d['quantity'] ?? 0).toDouble(),
      unitPrice: (d['unit_price'] ?? 0).toDouble(),
      amount: (d['amount'] ?? 0).toDouble(),
      note: d['note'],
    );
  }

  factory InvoiceServiceModel.fromSqlite(Map<String, dynamic> d) {
    return InvoiceServiceModel(
      id: d['id'] ?? '',
      invoiceId: d['invoice_id'] ?? '',
      serviceName: d['service_name'] ?? '',
      quantity: (d['quantity'] ?? 0).toDouble(),
      unitPrice: (d['unit_price'] ?? 0).toDouble(),
      amount: (d['amount'] ?? 0).toDouble(),
      note: d['note'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'invoice_id': invoiceId,
    'service_name': serviceName,
    'quantity': quantity,
    'unit_price': unitPrice,
    'amount': amount,
    'note': note,
  };

  Map<String, dynamic> toSqlite() => {
    'id': id,
    'invoice_id': invoiceId,
    'service_name': serviceName,
    'quantity': quantity,
    'unit_price': unitPrice,
    'amount': amount,
    'note': note,
  };
}

