import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../controllers/transaction_controller.dart';
import '../models/models.dart';
import 'home_screen.dart'; // Digunakan untuk formatCurrency
import 'form_transaction.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  String _selectedAggregation = 'Hari';

  Widget _glassWrapper({required Widget child, bool isDark = false, EdgeInsets? margin, EdgeInsets? padding}) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(isDark ? 35 : 120), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 25),
            blurRadius: 15,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            color: isDark ? Colors.white.withAlpha(15) : Colors.white.withAlpha(130),
            child: child,
          ),
        ),
      ),
    );
  }

  List<_GroupedData> _processData(List<TransactionModel> transactions) {
    Map<String, List<TransactionModel>> groupedMap = {};
    for (var tx in transactions) {
      String key;
      if (_selectedAggregation == 'Hari') {
        key = DateFormat('yyyy-MM-dd').format(tx.date);
      } else if (_selectedAggregation == 'Bulan') {
        key = DateFormat('yyyy-MM').format(tx.date);
      } else {
        key = DateFormat('yyyy').format(tx.date);
      }
      if (!groupedMap.containsKey(key)) groupedMap[key] = [];
      groupedMap[key]!.add(tx);
    }

    List<_GroupedData> result = groupedMap.entries.map((entry) {
      int income = 0;
      int expense = 0;
      for (var tx in entry.value) {
        if (tx.isIncome) income += tx.amount;
        else expense += tx.amount;
      }
      DateTime dateObj = DateTime.parse(entry.key.length == 4 ? "${entry.key}-01-01" : (entry.key.length == 7 ? "${entry.key}-01" : entry.key));
      String label;
      if (_selectedAggregation == 'Hari') label = DateFormat('dd MMM yyyy').format(dateObj);
      else if (_selectedAggregation == 'Bulan') label = DateFormat('MMMM yyyy').format(dateObj);
      else label = DateFormat('yyyy').format(dateObj);

      return _GroupedData(
        sortKey: entry.key,
        displayLabel: label,
        totalIncome: income,
        totalExpense: expense,
        transactions: entry.value,
      );
    }).toList();

    result.sort((a, b) => b.sortKey.compareTo(a.sortKey));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TransactionController>(context);
    final groupedData = _processData(controller.transactions);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned(
            top: 20, left: -30,
            child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withAlpha(isDark ? 40 : 60))),
          ),
          Positioned(
            bottom: 100, right: -40,
            child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purple.withAlpha(isDark ? 30 : 50))),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Riwayat", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      _glassWrapper(
                        isDark: isDark,
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedAggregation,
                            isDense: true,
                            // --- PERBAIKAN: DROPDOWN MELENGKUNG & GLASSY ---
                            borderRadius: BorderRadius.circular(20),
                            dropdownColor: isDark
                                ? const Color(0xFF1E293B).withAlpha(240)
                                : Colors.white.withAlpha(245),
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white70 : Colors.black54),
                            items: ['Hari', 'Bulan', 'Tahun'].map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedAggregation = val!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: groupedData.isEmpty
                      ? const Center(child: Text("Tidak ada data transaksi"))
                      : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: groupedData.length,
                    itemBuilder: (context, index) {
                      return TransactionGroupCard(data: groupedData[index], isDark: isDark);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedData {
  final String sortKey;
  final String displayLabel;
  final int totalIncome;
  final int totalExpense;
  final List<TransactionModel> transactions;
  _GroupedData({required this.sortKey, required this.displayLabel, required this.totalIncome, required this.totalExpense, required this.transactions});
}

class TransactionGroupCard extends StatefulWidget {
  final _GroupedData data;
  final bool isDark;
  const TransactionGroupCard({super.key, required this.data, required this.isDark});

  @override
  State<TransactionGroupCard> createState() => _TransactionGroupCardState();
}

class _TransactionGroupCardState extends State<TransactionGroupCard> {
  bool _isExpanded = false;

  Future<void> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text("Laporan Transaksi: ${widget.data.displayLabel}")),
          pw.Table.fromTextArray(
            headers: ['Tanggal', 'Nama', 'Tipe', 'Jumlah'],
            data: widget.data.transactions.map((tx) => [DateFormat('dd/MM/yy').format(tx.date), tx.name, tx.isIncome ? 'Masuk' : 'Keluar', formatCurrency(tx.amount)]).toList(),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // Di dalam class _TransactionGroupCardState file detail_screen.dart

  void _showDetailPopup(BuildContext context, TransactionModel tx, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withAlpha(200) : Colors.white.withAlpha(230),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(5))),
              const SizedBox(height: 20),
              Text("Detail Transaksi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              const Divider(height: 30),
              _buildRow("Nama", tx.name, isDark),
              _buildRow("Nominal", "Rp ${formatCurrency(tx.amount)}", isDark, color: tx.isIncome ? Colors.green : Colors.red, isBold: true),
              _buildRow("Kategori", tx.categoryName ?? '-', isDark),
              _buildRow("Catatan", tx.description.isEmpty ? '-' : tx.description, isDark),
              const SizedBox(height: 30),
              Row(
                children: [
                  // TOMBOL DELETE (BARU)
                  IconButton(
                    onPressed: () => _confirmDelete(context, tx.id!),
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    tooltip: "Hapus Transaksi",
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Tutup"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AddTransactionForm(transactionToEdit: tx)));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    child: const Text("Edit"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Transaksi?"),
        content: const Text("Data yang dihapus tidak dapat dikembalikan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Menutup dialog saja
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              // 1. Simpan referensi ScaffoldMessenger sebelum async
              final messenger = ScaffoldMessenger.of(context);

              // 2. Jalankan proses hapus
              await Provider.of<TransactionController>(context, listen: false).deleteTransaction(id);

              // 3. Cek apakah widget masih terpasang (Mounted)
              if (context.mounted) {
                // TUTUP DIALOG KONFIRMASI (pake ctx dari builder)
                Navigator.pop(ctx);

                // TUTUP BOTTOM SHEET DETAIL (pake context dari fungsi utama)
                Navigator.pop(context);

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text("Transaksi berhasil dihapus"),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String val, bool isDark, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
          Text(val, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: color ?? (isDark ? Colors.white : Colors.black87))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(widget.isDark ? 30 : 120), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: widget.isDark ? Colors.white.withAlpha(15) : Colors.white.withAlpha(130),
            child: Column(
              children: [
                ListTile(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  title: Text(widget.data.displayLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Net: Rp ${formatCurrency(widget.data.totalIncome - widget.data.totalExpense)}", style: TextStyle(color: (widget.data.totalIncome - widget.data.totalExpense) >= 0 ? Colors.green : Colors.red, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 20), onPressed: () => _generatePdf(context)),
                      Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20),
                    ],
                  ),
                ),
                if (_isExpanded)
                  ...widget.data.transactions.map((tx) => ListTile(
                    dense: true,
                    onTap: () => _showDetailPopup(context, tx, widget.isDark),
                    title: Text(tx.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(tx.categoryName ?? 'Umum', style: const TextStyle(fontSize: 11)),
                    trailing: Text("Rp ${formatCurrency(tx.amount)}", style: TextStyle(color: tx.isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}