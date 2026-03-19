import 'package:yh/models/invoice_model.dart';
import 'package:yh/models/invoice_service_model.dart';

abstract class IInvoiceService {
  Future<void> createInvoice(InvoiceModel invoice);
  Future<void> createInvoiceWithServices(
    InvoiceModel invoice,
    List<InvoiceServiceModel> services,
  );
  Future<bool> hasInvoiceForContractMonth(
    String contractId,
    int month,
    int year,
  );
  Future<List<InvoiceModel>> getAllInvoices();
  Future<List<InvoiceModel>> getInvoicesByTenant(String tenantId);
  Future<List<InvoiceServiceModel>> getInvoiceServices(String invoiceId);
  Future<void> markAsPaid(String invoiceId);
}
