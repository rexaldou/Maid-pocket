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
    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''CREATE TABLE tabungan (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nama TEXT, saldo REAL, limit_kuning REAL, limit_hijau REAL,
      tema_id INTEGER, banner_path TEXT
    )''');
    await db.execute('''CREATE TABLE transaksi (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tabungan_id INTEGER, amount REAL, notes TEXT, created_at TEXT
    )''');
  }

  Future _upgradeDB(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      // Tambah kolom limit kalau upgrade dari versi lama
    }
  }

  // --- CRUD TABUNGAN ---
  Future tambahTabungan(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('tabungan', data);
  }

  Future ambilSemuaTabungan() async {
    final db = await instance.database;
    return await db.query('tabungan', orderBy: 'id ASC');
  }

  Future updateSaldo(int id, double saldo) async {
    final db = await instance.database;
    return await db.update('tabungan', {'saldo': saldo}, where: 'id = ?', whereArgs: [id]);
  }

  Future updateTema(int id, int tema, String? path) async {
    final db = await instance.database;
    return await db.update('tabungan', {'tema_id': tema, 'banner_path': path}, where: 'id = ?', whereArgs: [id]);
  }

  Future updateLimit(int id, double kuning, double hijau) async {
    final db = await instance.database;
    return await db.update('tabungan', {'limit_kuning': kuning, 'limit_hijau': hijau}, where: 'id = ?', whereArgs: [id]);
  }

  Future hapusTabungan(int id) async {
    final db = await instance.database;
    await db.delete('transaksi', where: 'tabungan_id = ?', whereArgs: [id]);
    return await db.delete('tabungan', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD TRANSAKSI ---
  Future tambahTransaksi(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('transaksi', data);
  }

  Future ambilRiwayat(int idTabungan) async {
    final db = await instance.database;
    return await db.query('transaksi', where: 'tabungan_id = ?', whereArgs: [idTabungan], orderBy: 'created_at DESC');
  }

  Future updateTransaksi(int id, double amount, String notes, String date) async {
    final db = await instance.database;
    return await db.update('transaksi', {'amount': amount, 'notes': notes, 'created_at': date}, where: 'id = ?', whereArgs: [id]);
  }

  Future hapusTransaksi(int id) async {
    final db = await instance.database;
    return await db.delete('transaksi', where: 'id = ?', whereArgs: [id]);
  }

  String formatRupiah(double nominal) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(nominal);
  }
}