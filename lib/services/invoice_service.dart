import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/invoice_model.dart';
import '../models/invoice_service_model.dart';
import '../models/room_service_model.dart';
import '../core/interfaces/i_invoice_service.dart';
import 'local_db_service.dart';

class InvoiceService implements IInvoiceService {
  final _local = LocalDbService();
  final _col = FirebaseFirestore.instance.collection('invoices');
  final _invoiceServiceCol = FirebaseFirestore.instance.collection(
    'invoice_services',
  );
  final _roomServiceCol = FirebaseFirestore.instance.collection('room_services');

  String buildInvoiceId({
    required String contractId,
    required int month,
    required int year,
  }) {
    final normalizedContract = contractId
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return 'inv_${normalizedContract}_$year${month.toString().padLeft(2, '0')}';
  }

  /// Tạo hoá đơn — lưu SQLite trước, sync Firestore sau
  @override
  Future<void> createInvoice(InvoiceModel invoice) async {
    await createInvoiceWithServices(invoice, const []);
  }

  @override
  Future<void> createInvoiceWithServices(
    InvoiceModel invoice,
    List<InvoiceServiceModel> services,
  ) async {
    if (invoice.contractId.trim().isNotEmpty) {
      final existed = await hasInvoiceForContractMonth(
        invoice.contractId,
        invoice.month,
        invoice.year,
      );
      if (existed) {
        throw Exception('Hoa don thang nay da ton tai cho hop dong nay');
      }
    }

    final localInvoice = invoice.toSqlite()..['is_synced'] = 0;
    await _local.upsert('invoices', localInvoice);
    for (final service in services) {
      await _local.upsert('invoice_services', service.toSqlite());
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.set(_col.doc(invoice.id), invoice.toFirestore());
      for (final service in services) {
        batch.set(_invoiceServiceCol.doc(service.id), service.toFirestore());
      }
      await batch.commit();
      await _local.markSynced('invoices', invoice.id);
    } catch (_) {
      // Offline fallback: invoice and details already persisted in SQLite.
    }
  }

  @override
  Future<bool> hasInvoiceForContractMonth(
    String contractId,
    int month,
    int year,
  ) async {
    final normalized = contractId.trim();
    if (normalized.isEmpty) return false;

    final localRows = await _local.getAll(
      'invoices',
      where: 'contract_id = ? AND month = ? AND year = ?',
      whereArgs: [normalized, month, year],
    );
    if (localRows.isNotEmpty) return true;

    final remote = await _col
        .where('contract_id', isEqualTo: normalized)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .limit(1)
        .get();
    return remote.docs.isNotEmpty;
  }

  /// Lấy tất cả hoá đơn từ SQLite
  @override
  Future<List<InvoiceModel>> getAllInvoices() async {
    final rows = await _local.getAll('invoices', orderBy: 'year DESC, month DESC');
    return rows.map((r) => InvoiceModel.fromSqlite(r)).toList();
  }

  /// Lấy hoá đơn theo landlord
  Future<List<InvoiceModel>> getInvoicesByLandlord(String landlordId) async {
    // Luôn pull từ Firestore trước để đảm bảo data mới nhất
    try {
      final remote = await _col
          .where('landlord_id', isEqualTo: landlordId)
          .orderBy('year', descending: true)
          .orderBy('month', descending: true)
          .get();
      if (remote.docs.isNotEmpty) {
        final list = remote.docs.map(InvoiceModel.fromFirestore).toList();
        for (final inv in list) {
          await _local.upsert('invoices', inv.toSqlite()..['is_synced'] = 1);
        }
        return list;
      }
    } catch (_) {
      // Offline: fallback về SQLite
    }
    // Fallback SQLite khi offline
    final rows = await _local.getAll('invoices',
        where: 'landlord_id = ?',
        whereArgs: [landlordId],
        orderBy: 'year DESC, month DESC');
    return rows.map((r) => InvoiceModel.fromSqlite(r)).toList();
  }

  /// Lấy hoá đơn theo tenant
  @override
  Future<List<InvoiceModel>> getInvoicesByTenant(String tenantId) async {
    // Luôn pull từ Firestore trước để đảm bảo data mới nhất
    try {
      final remote = await _col
          .where('tenant_id', isEqualTo: tenantId)
          .orderBy('year', descending: true)
          .orderBy('month', descending: true)
          .get();
      if (remote.docs.isNotEmpty) {
        final list = remote.docs.map(InvoiceModel.fromFirestore).toList();
        for (final inv in list) {
          await _local.upsert('invoices', inv.toSqlite()..['is_synced'] = 1);
        }
        return list;
      }
    } catch (_) {
      // Offline: fallback về SQLite
    }
    // Fallback SQLite khi offline
    final rows = await _local.getAll('invoices',
        where: 'tenant_id = ?',
        whereArgs: [tenantId],
        orderBy: 'year DESC, month DESC');
    return rows.map((r) => InvoiceModel.fromSqlite(r)).toList();
  }

  @override
  Future<List<InvoiceServiceModel>> getInvoiceServices(String invoiceId) async {
    final localRows = await _local.getAll(
      'invoice_services',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    if (localRows.isNotEmpty) {
      return localRows.map(InvoiceServiceModel.fromSqlite).toList();
    }

    final remote = await _invoiceServiceCol
        .where('invoice_id', isEqualTo: invoiceId)
        .get();
    final list = remote.docs.map(InvoiceServiceModel.fromFirestore).toList();
    for (final item in list) {
      await _local.upsert('invoice_services', item.toSqlite());
    }
    return list;
  }

  Future<List<RoomServiceModel>> getRoomServicesByRoom(String roomId) async {
    final remote = await _roomServiceCol.where('room_id', isEqualTo: roomId).get();
    final services = remote.docs.map(RoomServiceModel.fromFirestore).toList();
    for (final service in services) {
      await _local.upsert('room_services', service.toSqlite());
    }
    return services;
  }

  /// Đánh dấu đã thanh toán
  @override
  Future<void> markAsPaid(String invoiceId) async {
    final now = DateTime.now();
    await _local.updateFields('invoices', invoiceId, {
      'status': 'paid',
      'paid_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    try {
      await _col.doc(invoiceId).update({
        'status': 'paid',
        'paid_at': Timestamp.fromDate(now),
        'updated_at': Timestamp.fromDate(now),
      });
    } catch (_) {}
  }
}
