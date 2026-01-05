import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // Untuk akses folder temporary saat export
import 'package:share_plus/share_plus.dart';       // Untuk fitur share file JSON
import 'package:file_picker/file_picker.dart';     // Untuk memilih file saat import
import '../database/database_helper.dart';
import '../models/models.dart';

class TransactionController extends ChangeNotifier {
  // --- STATE UTAMA ---
  List<TransactionModel> _allTransactions = []; // Semua data dari DB
  List<TransactionModel> _filteredTransactions = []; // Data yang tampil di UI (hasil filter)

  // --- STATE FILTER ---
  String _selectedFilter = 'Semua'; // Opsi: 'Semua', 'Tahun Ini', 'Bulan Ini'
  String get selectedFilter => _selectedFilter;

  // Getter untuk UI (selalu gunakan yang filtered)
  List<TransactionModel> get transactions => _filteredTransactions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- STATE TABUNGAN ---
  int _savingsBalance = 0;
  int get savingsBalance => _savingsBalance;

  int _lastMonthNetFlow = 0;
  int get lastMonthNetFlow => _lastMonthNetFlow;

  // ---------------------------------------------------------------------------
  // 1. LOAD DATA (Transaksi, Filter, Tabungan)
  // ---------------------------------------------------------------------------

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      // A. Ambil Semua Transaksi
      final dataList = await DatabaseHelper.instance.getAllTransactions();
      _allTransactions = dataList.map((item) => TransactionModel.fromMap(item)).toList();

      // B. Terapkan Filter yang sedang aktif
      _applyFilter();

      // C. Ambil Data Tabungan (user001)
      final savingsData = await DatabaseHelper.instance.getSavings();
      if (savingsData != null) {
        _savingsBalance = savingsData['tabungan'];
      } else {
        // Fallback jika data seeding hilang, hitung manual dari nol
        _savingsBalance = await _recalculateBalanceFromScratch();
      }

      // D. Ambil Statistik Bulan Lalu
      _lastMonthNetFlow = await DatabaseHelper.instance.getLastMonthNetFlow();

    } catch (e) {
      debugPrint("Error loading data: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // Helper: Hitung ulang saldo jika tabel tabungan korup/kosong
  Future<int> _recalculateBalanceFromScratch() async {
    int income = _allTransactions.where((t) => t.isIncome).fold(0, (sum, t) => sum + t.amount);
    int expense = _allTransactions.where((t) => !t.isIncome).fold(0, (sum, t) => sum + t.amount);
    int balance = income - expense;

    // Simpan hasil hitungan ke DB agar konsisten
    await DatabaseHelper.instance.updateSavings(balance);
    return balance;
  }

  // ---------------------------------------------------------------------------
  // 2. LOGIKA FILTERING
  // ---------------------------------------------------------------------------

  void setFilter(String filter) {
    _selectedFilter = filter;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    final now = DateTime.now();
    if (_selectedFilter == 'Semua') {
      _filteredTransactions = List.from(_allTransactions);
    } else if (_selectedFilter == 'Tahun Ini') {
      _filteredTransactions = _allTransactions.where((tx) => tx.date.year == now.year).toList();
    } else if (_selectedFilter == 'Bulan Ini') {
      _filteredTransactions = _allTransactions.where((tx) =>
      tx.date.year == now.year && tx.date.month == now.month
      ).toList();
    }
  }

  // ---------------------------------------------------------------------------
  // 3. MANIPULASI TRANSAKSI (CRUD) & UPDATE SALDO
  // ---------------------------------------------------------------------------

  Future<void> addTransaction(TransactionModel transaction) async {
    await DatabaseHelper.instance.createTransaction(transaction.toMap());

    // Logic: Update Saldo Tabungan saat transaksi bertambah
    // Pemasukan menambah saldo, Pengeluaran mengurangi saldo
    int adjustment = transaction.isIncome ? transaction.amount : -transaction.amount;
    await updateSavings(_savingsBalance + adjustment);

    // Reload semua data
    await loadTransactions();
  }

  // FITUR UPDATE (EDIT)
  Future<void> updateTransaction(TransactionModel transaction) async {
    // 1. Ambil data lama sebelum update untuk mengoreksi saldo
    final oldTx = _allTransactions.firstWhere((element) => element.id == transaction.id);

    // 2. Kembalikan saldo seolah transaksi lama dihapus (Reverse effect)
    int revertAdjustment = oldTx.isIncome ? -oldTx.amount : oldTx.amount;

    // 3. Hitung saldo baru seolah transaksi baru ditambahkan
    int newAdjustment = transaction.isIncome ? transaction.amount : -transaction.amount;

    // 4. Update Database Transaksi
    await DatabaseHelper.instance.updateTransaction(transaction.id!, transaction.toMap());

    // 5. Update Saldo Total (Saldo + Revert + New)
    await updateSavings(_savingsBalance + revertAdjustment + newAdjustment);

    await loadTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    // Cari data transaksi sebelum dihapus untuk mengembalikan saldo
    final tx = _allTransactions.firstWhere((element) => element.id == id, orElse: () => _allTransactions.first);

    // Revert logic: Hapus Pemasukan = Saldo Turun, Hapus Pengeluaran = Saldo Naik
    int adjustment = tx.isIncome ? -tx.amount : tx.amount;

    await DatabaseHelper.instance.deleteTransaction(id);
    await updateSavings(_savingsBalance + adjustment);

    await loadTransactions();
  }

  // Update ke Database Helper (Tabungan)
  Future<void> updateSavings(int newBalance) async {
    await DatabaseHelper.instance.updateSavings(newBalance);
    _savingsBalance = newBalance;
    // Kita tidak panggil notifyListeners disini karena biasanya dipanggil berbarengan dengan loadTransactions
  }

  // ---------------------------------------------------------------------------
  // 4. GETTER HITUNGAN (Untuk Home Screen)
  // Berdasarkan data yang SUDAH DI-FILTER
  // ---------------------------------------------------------------------------

  int get totalIncome {
    return _filteredTransactions
        .where((tx) => tx.isIncome)
        .fold(0, (sum, item) => sum + item.amount);
  }

  int get totalExpense {
    return _filteredTransactions
        .where((tx) => !tx.isIncome)
        .fold(0, (sum, item) => sum + item.amount);
  }

  int get currentBalance => totalIncome - totalExpense;

  // ---------------------------------------------------------------------------
  // 5. MANAJEMEN KATEGORI
  // ---------------------------------------------------------------------------

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  Future<void> loadCategories(bool isIncome) async {
    final dataList = await DatabaseHelper.instance.getCategoriesByType(isIncome);
    _categories = dataList.map((item) => Category.fromMap(item)).toList();
    notifyListeners();
  }

  Future<void> addCategory(String name, bool isIncome) async {
    final newCategory = Category(name: name, isIncome: isIncome);
    await DatabaseHelper.instance.createCategory(newCategory.toMap());
    await loadCategories(isIncome);
  }

  // ---------------------------------------------------------------------------
  // 6. FITUR MIGRASI & PENGATURAN DATA
  // ---------------------------------------------------------------------------

  // Ekspor Database ke JSON
  Future<void> exportDatabase() async {
    try {
      String jsonString = await DatabaseHelper.instance.getAllDataAsJson();

      // Simpan ke file temporary
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/backup_keuangan.json');
      await file.writeAsString(jsonString);

      // Share file tersebut
      await Share.shareXFiles([XFile(file.path)], text: 'Backup Data Keuangan');
    } catch (e) {
      debugPrint("Export Failed: $e");
      rethrow;
    }
  }

  // Impor Database dari JSON
  Future<void> importDatabase() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String jsonString = await file.readAsString();

        await DatabaseHelper.instance.restoreDataFromJson(jsonString);
        await loadTransactions(); // Refresh UI setelah restore
      }
    } catch (e) {
      debugPrint("Import Failed: $e");
      rethrow;
    }
  }

  // Reset Semua Data
  Future<void> resetData() async {
    await DatabaseHelper.instance.resetAllData();
    await loadTransactions(); // Refresh UI agar kosong/default
  }
}