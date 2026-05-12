import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Bikin wujud tunggal (Singleton) biar databasenya ga kebuka berkali-kali dan bikin HP lemot
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Buka atau bikin database baru kalau belum ada
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('maidpocket.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath(); // Minta izin lokasi ke sistem HP
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Bikin "Tabel" (kayak Excel) di dalam sistem HP kamu
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tabungan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        saldo REAL NOT NULL,
        icon INTEGER NOT NULL
      )
    ''');
  }

  // --- FUNGSI ALAT BANTU (CRUD) ---

  // 1. Simpan tabungan baru
  Future<int> tambahTabungan(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('tabungan', data);
  }

  // 2. Ambil semua data pas aplikasi baru dibuka
  Future<List<Map<String, dynamic>>> ambilSemuaTabungan() async {
    final db = await instance.database;
    return await db.query('tabungan');
  }

  // 3. Update saldo (kalau ada pemasukan/pengeluaran)
  Future<int> updateSaldo(int id, double saldoBaru) async {
    final db = await instance.database;
    return await db.update(
      'tabungan',
      {'saldo': saldoBaru},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 4. Hapus tabungan
  Future<int> hapusTabungan(int id) async {
    final db = await instance.database;
    return await db.delete('tabungan', where: 'id = ?', whereArgs: [id]);
  }
}
