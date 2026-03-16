import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_model.dart';

class InvoiceService {
  final _col = FirebaseFirestore.instance.collection('invoices');

  /// Tạo hoá đơn mới
  Future<void> createInvoice(InvoiceModel invoice) async {
    await _col.doc(invoice.id).set(invoice.toFirestore());
  }

  /// Lấy tất cả hoá đơn, sắp xếp mới nhất trước
  Stream<List<InvoiceModel>> getAllInvoices() {
    return _col.orderBy('createdAt', descending: true).snapshots().map((snap) =>
        snap.docs.map((d) => InvoiceModel.fromFirestore(d.data())).toList());
  }

  /// Lấy hoá đơn theo phòng
  Stream<List<InvoiceModel>> getInvoicesByRoom(String roomId) {
    return _col
        .where('roomId', isEqualTo: roomId)
        .orderBy('month', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => InvoiceModel.fromFirestore(d.data()))
            .toList());
  }

  /// Đánh dấu đã thanh toán
  Future<void> markAsPaid(String invoiceId) async {
    await _col.doc(invoiceId).update({'isPaid': true});
  }
}
