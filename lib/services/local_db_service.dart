import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Table for caching user profile
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

    // Table for caching invoices
    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        month TEXT,
        totalAmount REAL,
        isPaid INTEGER,
        electricityUsed REAL
      )
    ''');
  }

  // Helper methods to save and get data
  Future<void> saveProfile(Map<String, dynamic> profile) async {
    final db = await database;
    await db.insert('user_profile', profile, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final db = await database;
    final maps = await db.query('user_profile');
    if (maps.isNotEmpty) return maps.first;
    return null;
  }
}
