import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert'; // Untuk JSON encode/decode

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('personal_finance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Tabel Kategori
    await db.execute('''
      CREATE TABLE kategori (
        id_kategori INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_kategori TEXT NOT NULL,
        is_pemasukan INTEGER NOT NULL
      )
    ''');

    // 2. Tabel Transaksi
    await db.execute('''
      CREATE TABLE transaksi (
        id_transaksi INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        nominal INTEGER NOT NULL,
        keterangan TEXT,
        is_pemasukan INTEGER NOT NULL,
        id_kategori INTEGER NOT NULL,
        FOREIGN KEY (id_kategori) REFERENCES kategori (id_kategori) ON DELETE RESTRICT
      )
    ''');

    // 3. Tabel Tabungan (User ID Text untuk 'user001')
    await db.execute('''
      CREATE TABLE tabungan (
        user_id TEXT PRIMARY KEY,
        tabungan INTEGER NOT NULL
      )
    ''');

    // Isi data awal
    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // A. Seed Kategori
    await db.insert('kategori', {'nama_kategori': 'Gaji', 'is_pemasukan': 1});
    await db.insert('kategori', {'nama_kategori': 'Bonus', 'is_pemasukan': 1});
    await db.insert('kategori', {'nama_kategori': 'Investasi', 'is_pemasukan': 1});

    await db.insert('kategori', {'nama_kategori': 'Makan', 'is_pemasukan': 0});
    await db.insert('kategori', {'nama_kategori': 'Transport', 'is_pemasukan': 0});
    await db.insert('kategori', {'nama_kategori': 'Belanja', 'is_pemasukan': 0});
    await db.insert('kategori', {'nama_kategori': 'Tagihan', 'is_pemasukan': 0});

    // B. Seed Transaksi Dummy
    String today = DateTime.now().toIso8601String().split('T').first;

    await db.insert('transaksi', {
      'nama': 'Gaji Awal',
      'tanggal': today,
      'nominal': 5000000,
      'keterangan': 'Saldo awal sistem',
      'is_pemasukan': 1,
      'id_kategori': 1
    });

    await db.insert('transaksi', {
      'nama': 'Makan Siang',
      'tanggal': today,
      'nominal': 50000,
      'keterangan': 'Contoh pengeluaran',
      'is_pemasukan': 0,
      'id_kategori': 4
    });

    // C. Kalkulasi Saldo Awal
    final incomeRes = await db.rawQuery('SELECT SUM(nominal) as total FROM transaksi WHERE is_pemasukan = 1');
    final expenseRes = await db.rawQuery('SELECT SUM(nominal) as total FROM transaksi WHERE is_pemasukan = 0');

    int income = (incomeRes.first['total'] as int?) ?? 0;
    int expense = (expenseRes.first['total'] as int?) ?? 0;
    int initialBalance = income - expense;

    // D. Masukkan ke Tabel Tabungan
    await db.insert('tabungan', {
      'user_id': 'user001',
      'tabungan': initialBalance
    });
  }

  // ===========================================================================
  // CRUD KATEGORI
  // ===========================================================================

  Future<int> createCategory(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('kategori', row);
  }

  Future<List<Map<String, dynamic>>> getCategoriesByType(bool isPemasukan) async {
    final db = await instance.database;
    final int typeVal = isPemasukan ? 1 : 0;
    return await db.query(
      'kategori',
      where: 'is_pemasukan = ?',
      whereArgs: [typeVal],
      orderBy: 'nama_kategori ASC',
    );
  }

  // ===========================================================================
  // CRUD TRANSAKSI
  // ===========================================================================

  Future<int> createTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('transaksi', row);
  }

  Future<int> updateTransaction(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'transaksi',
      row,
      where: 'id_transaksi = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT 
        t.id_transaksi, 
        t.nama, 
        t.tanggal, 
        t.nominal, 
        t.keterangan, 
        t.is_pemasukan,
        t.id_kategori,
        k.nama_kategori
      FROM transaksi t
      INNER JOIN kategori k ON t.id_kategori = k.id_kategori
      ORDER BY t.tanggal DESC, t.id_transaksi DESC
    ''');
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transaksi', where: 'id_transaksi = ?', whereArgs: [id]);
  }

  // ===========================================================================
  // FITUR TABUNGAN (USER001)
  // ===========================================================================

  Future<Map<String, dynamic>?> getSavings() async {
    final db = await instance.database;
    final res = await db.query('tabungan', where: 'user_id = ?', whereArgs: ['user001']);
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> updateSavings(int amount) async {
    final db = await instance.database;
    return await db.insert(
        'tabungan',
        {'user_id': 'user001', 'tabungan': amount},
        conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  Future<int> getLastMonthNetFlow() async {
    final db = await instance.database;
    final now = DateTime.now();
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final currentMonthStart = DateTime(now.year, now.month, 1);

    final startStr = lastMonthStart.toIso8601String().split('T').first;
    final endStr = currentMonthStart.toIso8601String().split('T').first;

    final incomeRes = await db.rawQuery(
        'SELECT SUM(nominal) as total FROM transaksi WHERE is_pemasukan = 1 AND tanggal >= ? AND tanggal < ?',
        [startStr, endStr]
    );
    int income = (incomeRes.first['total'] as int?) ?? 0;

    final expenseRes = await db.rawQuery(
        'SELECT SUM(nominal) as total FROM transaksi WHERE is_pemasukan = 0 AND tanggal >= ? AND tanggal < ?',
        [startStr, endStr]
    );
    int expense = (expenseRes.first['total'] as int?) ?? 0;

    return income - expense;
  }

  // ===========================================================================
  // FITUR MIGRASI & RESET DATA (BARU)
  // ===========================================================================

  // 1. Ekspor Data ke JSON String
  Future<String> getAllDataAsJson() async {
    final db = await instance.database;

    // Ambil semua data mentah
    final categories = await db.query('kategori');
    final transactions = await db.query('transaksi');
    final savings = await db.query('tabungan');

    // Bungkus dalam Map
    final Map<String, dynamic> data = {
      'kategori': categories,
      'transaksi': transactions,
      'tabungan': savings,
    };

    // Encode ke JSON String
    return jsonEncode(data);
  }

  // 2. Restore Data dari JSON String
  Future<void> restoreDataFromJson(String jsonString) async {
    final db = await instance.database;
    final Map<String, dynamic> data = jsonDecode(jsonString);

    await db.transaction((txn) async {
      // Hapus data lama (Bersih-bersih)
      await txn.delete('transaksi');
      await txn.delete('kategori');
      await txn.delete('tabungan');

      // Restore Kategori
      if (data['kategori'] != null) {
        for (var item in (data['kategori'] as List)) {
          await txn.insert('kategori', item);
        }
      }

      // Restore Transaksi
      if (data['transaksi'] != null) {
        for (var item in (data['transaksi'] as List)) {
          await txn.insert('transaksi', item);
        }
      }

      // Restore Tabungan
      if (data['tabungan'] != null) {
        for (var item in (data['tabungan'] as List)) {
          await txn.insert('tabungan', item);
        }
      }
    });
  }

  // 3. Reset Total (Hapus Semua & Seeding Ulang)
  Future<void> resetAllData() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // Hapus semua tabel
      await txn.delete('transaksi');
      await txn.delete('kategori');
      await txn.delete('tabungan');

      // Lakukan Seeding Ulang agar aplikasi usable (tidak kosong melompong)
      // Insert Kategori Default
      await txn.insert('kategori', {'nama_kategori': 'Gaji', 'is_pemasukan': 1});
      await txn.insert('kategori', {'nama_kategori': 'Bonus', 'is_pemasukan': 1});
      await txn.insert('kategori', {'nama_kategori': 'Investasi', 'is_pemasukan': 1});
      await txn.insert('kategori', {'nama_kategori': 'Makan', 'is_pemasukan': 0});
      await txn.insert('kategori', {'nama_kategori': 'Transport', 'is_pemasukan': 0});
      await txn.insert('kategori', {'nama_kategori': 'Belanja', 'is_pemasukan': 0});
      await txn.insert('kategori', {'nama_kategori': 'Tagihan', 'is_pemasukan': 0});

      // Reset Tabungan user001 ke 0
      await txn.insert('tabungan', {'user_id': 'user001', 'tabungan': 0});
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}