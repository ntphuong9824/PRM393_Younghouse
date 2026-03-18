import '../../models/invoice_model.dart';

abstract class IInvoiceService {
  Future<void> createInvoice(InvoiceModel invoice);
  Future<List<InvoiceModel>> getAllInvoices();
  Future<List<InvoiceModel>> getInvoicesByTenant(String tenantId);
  Future<void> markAsPaid(String invoiceId);
}
