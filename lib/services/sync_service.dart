import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_db_service.dart';

/// SyncService: đồng bộ dữ liệu giữa SQLite (local) và Firestore (cloud)
/// Nguyên tắc: App đọc/ghi SQLite trước, sync lên Firestore sau
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _local = LocalDbService();

  // ── Collections cần sync (có is_synced flag) ──────────────────
  static const _syncableTables = [
    'users', 'properties', 'rooms', 'room_services',
    'contracts', 'invoices', 'payments',
  ];

  // ── Map table → Firestore collection name ─────────────────────
  static const _collectionMap = {
    'users': 'users',
    'properties': 'properties',
    'rooms': 'rooms',
    'room_services': 'room_services',
    'contracts': 'contracts',
    'invoices': 'invoices',
    'payments': 'payments',
  };

  /// Đẩy tất cả records chưa sync lên Firestore
  Future<void> pushUnsynced() async {
    for (final table in _syncableTables) {
      final unsynced = await _local.getUnsynced(table);
      for (final row in unsynced) {
        try {
          final collection = _collectionMap[table]!;
          final id = row['id'] as String;
          final data = Map<String, dynamic>.from(row)
            ..remove('id')
            ..remove('is_synced');
          await _firestore.collection(collection).doc(id).set(data, SetOptions(merge: true));
          await _local.markSynced(table, id);
        } catch (e) {
          // Giữ is_synced = 0 để retry lần sau
        }
      }
    }
  }

  /// Pull data từ Firestore về SQLite cho một user (landlord)
  Future<void> pullForLandlord(String landlordId) async {
    await Future.wait([
      _pullCollection('properties', 'landlord_id', landlordId),
      _pullCollection('rooms', 'property_id', null, extraQuery: (q) =>
          q.where('landlord_id', isEqualTo: landlordId)),
      _pullCollection('contracts', 'landlord_id', landlordId),
      _pullCollection('invoices', 'landlord_id', landlordId),
      _pullCollection('payments', 'landlord_id', landlordId),
    ]);
  }

  /// Pull data từ Firestore về SQLite cho một tenant
  Future<void> pullForTenant(String tenantId) async {
    await Future.wait([
      _pullCollection('contracts', 'tenant_id', tenantId),
      _pullCollection('invoices', 'tenant_id', tenantId),
      _pullCollection('payments', 'tenant_id', tenantId),
    ]);
  }

  Future<void> _pullCollection(
    String collection,
    String field,
    String? value, {
    Query Function(Query)? extraQuery,
  }) async {
    try {
      Query query = _firestore.collection(collection);
      if (value != null) query = query.where(field, isEqualTo: value);
      if (extraQuery != null) query = extraQuery(query);

      final snapshot = await query.get();
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Convert Timestamps → ISO string cho SQLite
        final sqliteData = _convertForSqlite(data);
        sqliteData['id'] = doc.id;
        sqliteData['is_synced'] = 1;
        await _local.upsert(collection, sqliteData);
      }
    } catch (_) {}
  }

  /// Lắng nghe realtime từ Firestore và cập nhật SQLite ngay lập tức
  void listenRealtime(String collection, String field, String value) {
    _firestore
        .collection(collection)
        .where(field, isEqualTo: value)
        .snapshots()
        .listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          await _local.delete(collection, change.doc.id);
        } else {
          final data = change.doc.data() as Map<String, dynamic>;
          final sqliteData = _convertForSqlite(data);
          sqliteData['id'] = change.doc.id;
          sqliteData['is_synced'] = 1;
          await _local.upsert(collection, sqliteData);
        }
      }
    });
  }

  /// Convert Firestore Timestamp và List → SQLite-compatible types
  Map<String, dynamic> _convertForSqlite(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is Timestamp) {
        result[entry.key] = value.toDate().toIso8601String();
      } else if (value is List) {
        result[entry.key] = value.join(',');
      } else if (value is bool) {
        result[entry.key] = value ? 1 : 0;
      } else {
        result[entry.key] = value;
      }
    }
    return result;
  }
}
