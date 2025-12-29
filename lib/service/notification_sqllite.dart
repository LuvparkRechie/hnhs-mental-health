import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AdminAlertDB {
  static final AdminAlertDB instance = AdminAlertDB._init();
  static Database? _db;

  AdminAlertDB._init();

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), "admin_alerts.db");

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE admin_alerts (
            id INTEGER PRIMARY KEY,
            user_message TEXT,
            description TEXT
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> insertAlert(Map<String, dynamic> alert) async {
    final db = await database;
    await db.insert(
      "admin_alerts",
      alert,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<Map<String, dynamic>?> getAlert(int id) async {
    final db = await database;
    final result = await db.query(
      "admin_alerts",
      where: "id = ?",
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> deleteAll() async {
    final db = await database;
    await db.delete("admin_alerts");
  }
}
