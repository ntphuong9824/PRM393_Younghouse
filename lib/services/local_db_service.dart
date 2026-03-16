import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/invoice_model.dart';
import '../models/room_model.dart';

class LocalDbService {
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
        version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id TEXT PRIMARY KEY,
        fullName TEXT,
        dob TEXT,
        cccd TEXT,
        address TEXT,
        fatherName TEXT,
        fatherPhone TEXT,
        motherName TEXT,
        motherPhone TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        roomId TEXT,
        roomName TEXT,
        baseRent REAL,
        waterServicePerPerson REAL,
        numberOfPeople INTEGER,
        electricityPricePerUnit REAL,
        month TEXT,
        electricityStart REAL,
        electricityEnd REAL,
        isPaid INTEGER,
        createdAt TEXT
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS invoices');
      await db.execute('''
        CREATE TABLE invoices (
          id TEXT PRIMARY KEY,
          roomId TEXT,
          roomName TEXT,
          baseRent REAL,
          waterServicePerPerson REAL,
          numberOfPeople INTEGER,
          electricityPricePerUnit REAL,
          month TEXT,
          electricityStart REAL,
          electricityEnd REAL,
          isPaid INTEGER,
          createdAt TEXT
        )
      ''');
    }
  }

  // --- User Profile ---
  Future<void> saveProfile(Map<String, dynamic> profile) async {
    final db = await database;
    await db.insert('user_profile', profile,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final db = await database;
    final maps = await db.query('user_profile');
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  // --- Invoices ---
  Future<void> saveInvoice(InvoiceModel invoice) async {
    final db = await database;
    await db.insert(
        'invoices',
        {
          'id': invoice.id,
          'roomId': invoice.room.roomId,
          'roomName': invoice.room.roomName,
          'baseRent': invoice.room.baseRent,
          'waterServicePerPerson': invoice.room.waterServicePerPerson,
          'numberOfPeople': invoice.room.numberOfPeople,
          'electricityPricePerUnit': invoice.room.electricityPricePerUnit,
          'month': invoice.month.toIso8601String(),
          'electricityStart': invoice.electricityStart,
          'electricityEnd': invoice.electricityEnd,
          'isPaid': invoice.isPaid ? 1 : 0,
          'createdAt': (invoice.createdAt ?? DateTime.now()).toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<InvoiceModel>> getAllInvoices() async {
    final db = await database;
    final maps = await db.query('invoices', orderBy: 'createdAt DESC');
    return maps.map((m) {
      final room = RoomModel(
        roomId: m['roomId'] as String,
        roomName: m['roomName'] as String,
        baseRent: m['baseRent'] as double,
        waterServicePerPerson: m['waterServicePerPerson'] as double,
        numberOfPeople: m['numberOfPeople'] as int,
        electricityPricePerUnit: m['electricityPricePerUnit'] as double,
      );
      return InvoiceModel(
        id: m['id'] as String,
        room: room,
        month: DateTime.parse(m['month'] as String),
        electricityStart: m['electricityStart'] as double,
        electricityEnd: m['electricityEnd'] as double,
        isPaid: (m['isPaid'] as int) == 1,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
    }).toList();
  }

  Future<void> markAsPaid(String invoiceId) async {
    final db = await database;
    await db.update('invoices', {'isPaid': 1},
        where: 'id = ?', whereArgs: [invoiceId]);
  }
}
