import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_model.dart';
import 'interfaces/i_invoice_service.dart';
import 'local_db_service.dart';

class InvoiceService implements IInvoiceService {
  final _local = LocalDbService();
  final _col = FirebaseFirestore.instance.collection('invoices');

  /// Tạo hoá đơn — lưu SQLite trước, sync Firestore sau
  @override
  Future<void> createInvoice(InvoiceModel invoice) async {
    await _local.upsert('invoices', invoice.toSqlite());
    try {
      await _col.doc(invoice.id).set(invoice.toFirestore());
    } catch (_) {
      // offline fallback — đã lưu local
    }
  }

  /// Lấy tất cả hoá đơn từ SQLite
  @override
  Future<List<InvoiceModel>> getAllInvoices() async {
    final rows = await _local.getAll('invoices', orderBy: 'year DESC, month DESC');
    return rows.map((r) => InvoiceModel.fromSqlite(r)).toList();
  }

  /// Lấy hoá đơn theo tenant
  @override
  Future<List<InvoiceModel>> getInvoicesByTenant(String tenantId) async {
    final rows = await _local.getAll('invoices',
        where: 'tenant_id = ?',
        whereArgs: [tenantId],
        orderBy: 'year DESC, month DESC');
    return rows.map((r) => InvoiceModel.fromSqlite(r)).toList();
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
