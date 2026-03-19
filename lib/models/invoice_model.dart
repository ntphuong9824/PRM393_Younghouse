import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceModel {
  final String id;
  final String contractId;
  final String roomId;
  final String tenantId;
  final String landlordId;
  final int month;
  final int year;
  final int electricPrev;
  final int electricCurr;
  final double electricPrice;
  final int waterPrev;
  final int waterCurr;
  final double waterPrice;
  final double rentAmount;
  final double otherFees;
  final double totalAmount;
  final String status; // unpaid / paid / overdue
  final DateTime dueDate;
  final DateTime? paidAt;
  final String? paymentMethod;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  InvoiceModel({
    required this.id,
    required this.contractId,
    required this.roomId,
    required this.tenantId,
    required this.landlordId,
    required this.month,
    required this.year,
    this.electricPrev = 0,
    this.electricCurr = 0,
    this.electricPrice = 0,
    this.waterPrev = 0,
    this.waterCurr = 0,
    this.waterPrice = 0,
    required this.rentAmount,
    this.otherFees = 0,
    required this.totalAmount,
    this.status = 'unpaid',
    required this.dueDate,
    this.paidAt,
    this.paymentMethod,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  int get electricUsed => electricCurr - electricPrev;
  double get electricCost => electricUsed * electricPrice;
  int get waterUsed => waterCurr - waterPrev;
  double get waterCost => waterUsed * waterPrice;
  /// Phí dịch vụ chung = otherFees (đã lưu sẵn khi tạo hóa đơn, không tính điện)
  double get serviceFees => otherFees;

  factory InvoiceModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return InvoiceModel(
      id: doc.id,
      contractId: d['contract_id'] ?? '',
      roomId: d['room_id'] ?? '',
      tenantId: d['tenant_id'] ?? '',
      landlordId: d['landlord_id'] ?? '',
      month: d['month'] ?? 1,
      year: d['year'] ?? DateTime.now().year,
      electricPrev: d['electric_prev'] ?? 0,
      electricCurr: d['electric_curr'] ?? 0,
      electricPrice: (d['electric_price'] ?? 0).toDouble(),
      waterPrev: d['water_prev'] ?? 0,
      waterCurr: d['water_curr'] ?? 0,
      waterPrice: (d['water_price'] ?? 0).toDouble(),
      rentAmount: (d['rent_amount'] ?? 0).toDouble(),
      otherFees: (d['other_fees'] ?? 0).toDouble(),
      totalAmount: (d['total_amount'] ?? 0).toDouble(),
      status: d['status'] ?? 'unpaid',
      dueDate: (d['due_date'] as Timestamp).toDate(),
      paidAt: d['paid_at'] != null ? (d['paid_at'] as Timestamp).toDate() : null,
      paymentMethod: d['payment_method'],
      notes: d['notes'],
      createdBy: d['created_by'] ?? '',
      createdAt: (d['created_at'] as Timestamp).toDate(),
      updatedAt: (d['updated_at'] as Timestamp).toDate(),
    );
  }

  factory InvoiceModel.fromSqlite(Map<String, dynamic> d) {
    return InvoiceModel(
      id: d['id'],
      contractId: d['contract_id'] ?? '',
      roomId: d['room_id'] ?? '',
      tenantId: d['tenant_id'] ?? '',
      landlordId: d['landlord_id'] ?? '',
      month: d['month'] ?? 1,
      year: d['year'] ?? DateTime.now().year,
      electricPrev: d['electric_prev'] ?? 0,
      electricCurr: d['electric_curr'] ?? 0,
      electricPrice: d['electric_price'] ?? 0.0,
      waterPrev: d['water_prev'] ?? 0,
      waterCurr: d['water_curr'] ?? 0,
      waterPrice: d['water_price'] ?? 0.0,
      rentAmount: d['rent_amount'] ?? 0.0,
      otherFees: d['other_fees'] ?? 0.0,
      totalAmount: d['total_amount'] ?? 0.0,
      status: d['status'] ?? 'unpaid',
      dueDate: DateTime.parse(d['due_date']),
      paidAt: d['paid_at'] != null ? DateTime.parse(d['paid_at']) : null,
      paymentMethod: d['payment_method'],
      notes: d['notes'],
      createdBy: d['created_by'] ?? '',
      createdAt: DateTime.parse(d['created_at']),
      updatedAt: DateTime.parse(d['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'contract_id': contractId,
    'room_id': roomId,
    'tenant_id': tenantId,
    'landlord_id': landlordId,
    'month': month,
    'year': year,
    'electric_prev': electricPrev,
    'electric_curr': electricCurr,
    'electric_price': electricPrice,
    'water_prev': waterPrev,
    'water_curr': waterCurr,
    'water_price': waterPrice,
    'rent_amount': rentAmount,
    'other_fees': otherFees,
    'total_amount': totalAmount,
    'status': status,
    'due_date': Timestamp.fromDate(dueDate),
    'paid_at': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    'payment_method': paymentMethod,
    'notes': notes,
    'created_by': createdBy,
    'created_at': Timestamp.fromDate(createdAt),
    'updated_at': Timestamp.fromDate(updatedAt),
  };

  Map<String, dynamic> toSqlite() => {
    'id': id,
    'contract_id': contractId,
    'room_id': roomId,
    'tenant_id': tenantId,
    'landlord_id': landlordId,
    'month': month,
    'year': year,
    'electric_prev': electricPrev,
    'electric_curr': electricCurr,
    'electric_price': electricPrice,
    'water_prev': waterPrev,
    'water_curr': waterCurr,
    'water_price': waterPrice,
    'rent_amount': rentAmount,
    'other_fees': otherFees,
    'total_amount': totalAmount,
    'status': status,
    'due_date': dueDate.toIso8601String(),
    'paid_at': paidAt?.toIso8601String(),
    'payment_method': paymentMethod,
    'notes': notes,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'is_synced': 1,
  };
}
