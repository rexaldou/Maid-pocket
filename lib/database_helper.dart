import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('maidpocket_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tabungan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        saldo REAL NOT NULL,
        limit_kuning REAL DEFAULT 50000,
        limit_hijau REAL DEFAULT 500000,
        limit_biru REAL DEFAULT 1000000,
        tema_id INTEGER DEFAULT 0,
        banner_path TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tabungan_id INTEGER,
        amount REAL,
        notes TEXT,
        created_at TEXT
      )
    ''');
  }

  Future<int> tambahTabungan(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('tabungan', data);
  }

  Future<List<Map<String, dynamic>>> ambilSemuaTabungan() async {
    final db = await instance.database;
    return await db.query('tabungan');
  }

  Future<int> updateSaldo(int id, double saldo) async {
    final db = await instance.database;
    return await db.update('tabungan', {'saldo': saldo}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateTema(int id, int temaId, String? path) async {
    final db = await instance.database;
    return await db.update('tabungan', {'tema_id': temaId, 'banner_path': path}, where: 'id = ?', whereArgs: [id]);
  }
  
  // Fungsi baru buat update limit kesenjangan sosial
  Future<int> updateLimit(int id, double kuning, double hijau) async {
    final db = await instance.database;
    return await db.update('tabungan', {'limit_kuning': kuning, 'limit_hijau': hijau}, where: 'id = ?', whereArgs: [id]);
  }

  // Fungsi baru buat hapus dompet dan semua riwayatnya (Cascade Delete)
  Future<int> hapusTabungan(int id) async {
    final db = await instance.database;
    await db.delete('transactions', where: 'tabungan_id = ?', whereArgs: [id]);
    return await db.delete('tabungan', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> tambahTransaksi(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('transactions', data);
  }

  Future<List<Map<String, dynamic>>> ambilRiwayat(int id) async {
    final db = await instance.database;
    return await db.query('transactions', where: 'tabungan_id = ?', whereArgs: [id], orderBy: 'created_at DESC');
  }

  Future<int> hapusTransaksi(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  String formatRupiah(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }
}