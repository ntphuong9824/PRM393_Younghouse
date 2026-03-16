import '../models/invoice_model.dart';
import 'local_db_service.dart';

class InvoiceService {
  final _db = LocalDbService();

  Future<void> createInvoice(InvoiceModel invoice) async {
    await _db.saveInvoice(invoice);
  }

  Future<List<InvoiceModel>> getAllInvoices() async {
    return await _db.getAllInvoices();
  }

  Future<void> markAsPaid(String invoiceId) async {
    await _db.markAsPaid(invoiceId);
  }
}
