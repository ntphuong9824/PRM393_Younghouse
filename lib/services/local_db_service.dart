import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('young_house.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path,
        version: 5, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Drop bảng có schema thay đổi rồi tạo lại
    await db.execute('DROP TABLE IF EXISTS invoices');
    await db.execute('DROP TABLE IF EXISTS users');
    await db.execute('DROP TABLE IF EXISTS guardians');
    await _createDB(db, newVersion);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT,
        phone TEXT,
        full_name TEXT,
        avatar_url TEXT,
        role TEXT,
        landlord_id TEXT,
        date_of_birth TEXT,
        id_number TEXT,
        id_front_url TEXT,
        id_back_url TEXT,
        is_profile_confirmed INTEGER DEFAULT 0,
        fcm_token TEXT,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS properties (
        id TEXT PRIMARY KEY,
        landlord_id TEXT,
        name TEXT,
        address TEXT,
        ward TEXT,
        district TEXT,
        city TEXT,
        description TEXT,
        total_rooms INTEGER DEFAULT 0,
        status TEXT DEFAULT 'active',
        images TEXT,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS rooms (
        id TEXT PRIMARY KEY,
        property_id TEXT,
        current_tenant_id TEXT,
        current_contract_id TEXT,
        room_number TEXT,
        floor INTEGER DEFAULT 1,
        area_sqm REAL DEFAULT 0,
        base_price REAL DEFAULT 0,
        deposit_amount REAL DEFAULT 0,
        description TEXT,
        images TEXT,
        status TEXT DEFAULT 'vacant',
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS room_services (
        id TEXT PRIMARY KEY,
        room_id TEXT,
        service_name TEXT,
        unit TEXT,
        price_per_unit REAL DEFAULT 0,
        is_metered INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS contracts (
        id TEXT PRIMARY KEY,
        room_id TEXT,
        tenant_id TEXT,
        landlord_id TEXT,
        start_date TEXT,
        end_date TEXT,
        monthly_rent REAL DEFAULT 0,
        deposit REAL DEFAULT 0,
        co_tenants TEXT,
        terms TEXT,
        status TEXT DEFAULT 'active',
        pdf_url TEXT,
        signed_at TEXT,
        terminated_at TEXT,
        termination_reason TEXT,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoices (
        id TEXT PRIMARY KEY,
        contract_id TEXT,
        room_id TEXT,
        tenant_id TEXT,
        landlord_id TEXT,
        month INTEGER,
        year INTEGER,
        electric_prev INTEGER DEFAULT 0,
        electric_curr INTEGER DEFAULT 0,
        electric_price REAL DEFAULT 0,
        water_prev INTEGER DEFAULT 0,
        water_curr INTEGER DEFAULT 0,
        water_price REAL DEFAULT 0,
        rent_amount REAL DEFAULT 0,
        other_fees REAL DEFAULT 0,
        total_amount REAL DEFAULT 0,
        status TEXT DEFAULT 'unpaid',
        due_date TEXT,
        paid_at TEXT,
        payment_method TEXT,
        notes TEXT,
        created_by TEXT,
        created_at TEXT,
        updated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoice_services (
        id TEXT PRIMARY KEY,
        invoice_id TEXT,
        service_name TEXT,
        quantity REAL DEFAULT 0,
        unit_price REAL DEFAULT 0,
        amount REAL DEFAULT 0,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id TEXT PRIMARY KEY,
        invoice_id TEXT,
        tenant_id TEXT,
        landlord_id TEXT,
        amount REAL DEFAULT 0,
        method TEXT,
        note TEXT,
        receipt_url TEXT,
        paid_at TEXT,
        created_by TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS guardians (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        full_name TEXT,
        phone TEXT,
        relationship TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id TEXT PRIMARY KEY,
        title TEXT,
        message TEXT,
        created_at TEXT,
        target_user_id TEXT,
        read_by TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_rooms (
        id TEXT PRIMARY KEY,
        room_id TEXT,
        landlord_id TEXT,
        tenant_id TEXT,
        last_message TEXT,
        last_message_at TEXT,
        unread_landlord INTEGER DEFAULT 0,
        unread_tenant INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id TEXT PRIMARY KEY,
        chat_room_id TEXT,
        sender_id TEXT,
        content TEXT,
        type TEXT DEFAULT 'text',
        file_url TEXT,
        sent_at TEXT,
        is_read INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  // ── Generic helpers ──────────────────────────────────────────────

  Future<void> upsert(String table, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAll(String table,
      {String? where, List<dynamic>? whereArgs, String? orderBy}) async {
    final db = await database;
    return db.query(table,
        where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  Future<Map<String, dynamic>?> getById(String table, String id) async {
    final db = await database;
    final rows = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<void> delete(String table, String id) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getUnsynced(String table) async {
    final db = await database;
    return db.query(table, where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<void> markSynced(String table, String id) async {
    final db = await database;
    await db.update(table, {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateFields(String table, String id, Map<String, dynamic> fields) async {
    final db = await database;
    await db.update(table, fields, where: 'id = ?', whereArgs: [id]);
  }
}
