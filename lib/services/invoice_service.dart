import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_model.dart';
import 'local_db_service.dart';

class InvoiceService {
  final _db = LocalDbService();
  final _col = FirebaseFirestore.instance.collection('invoices');

  /// Tạo hoá đơn — lưu SQLite trước, sync Firestore sau
  Future<void> createInvoice(InvoiceModel invoice) async {
    await _db.upsert('invoices', invoice.toSqlite());
    try {
      await _col.doc(invoice.id).set(invoice.toFirestore());
    } catch (_) {
      // offline fallback — đã lưu local
    }
  }

  /// Lấy tất cả hoá đơn từ SQLite
  Future<List<InvoiceModel>> getAllInvoices() async {
    final rows = await _db.getAll('invoices', orderBy: 'year DESC, month DESC');
    return rows.map((r) => InvoiceModel.fromSqlite(r)).toList();
  }

  /// Lấy hoá đơn theo tenant
  Future<List<InvoiceModel>> getInvoicesByTenant(String tenantId) async {
    final rows = await _db.getAll('invoices',
        where: 'tenant_id = ?',
        whereArgs: [tenantId],
        orderBy: 'year DESC, month DESC');
    return rows.map((r) => InvoiceModel.fromSqlite(r)).toList();
  }

  /// Đánh dấu đã thanh toán
  Future<void> markAsPaid(String invoiceId) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'invoices',
      {'status': 'paid', 'paid_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
    try {
      await _col.doc(invoiceId).update({
        'status': 'paid',
        'paid_at': Timestamp.fromDate(DateTime.now()),
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });
    } catch (_) {}
  }
}
