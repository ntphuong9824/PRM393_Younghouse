/// Tập trung tất cả magic strings, collection names, status values
class AppConstants {
  AppConstants._();

  // Firestore collections
  static const String colUsers = 'users';
  static const String colProperties = 'properties';
  static const String colRooms = 'rooms';
  static const String colRoomServices = 'room_services';
  static const String colContracts = 'contracts';
  static const String colInvoices = 'invoices';
  static const String colPayments = 'payments';
  static const String colNotifications = 'notifications';
  static const String colChatRooms = 'chat_rooms';
  static const String colMessages = 'messages';

  // User roles
  static const String roleAdmin = 'admin';
  static const String roleTenant = 'tenant';

  // Room status
  static const String roomVacant = 'vacant';
  static const String roomOccupied = 'occupied';
  static const String roomMaintenance = 'maintenance';

  // Property status
  static const String propertyActive = 'active';
  static const String propertyInactive = 'inactive';

  // Contract status
  static const String contractActive = 'active';
  static const String contractExpired = 'expired';
  static const String contractTerminated = 'terminated';

  // Invoice status
  static const String invoiceUnpaid = 'unpaid';
  static const String invoicePaid = 'paid';
  static const String invoiceOverdue = 'overdue';

  // Payment methods
  static const String paymentCash = 'cash';
  static const String paymentTransfer = 'transfer';
  static const String paymentPayos = 'payos';

  // SQLite DB
  static const String dbName = 'young_house.db';
  static const int dbVersion = 5;

  // Temp admin ID (replace with real auth later)
  static const String tempAdminId = 'admin_001';
}
