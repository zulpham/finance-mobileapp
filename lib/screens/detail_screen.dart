import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../controllers/transaction_controller.dart';
import '../models/models.dart';
import 'home_screen.dart'; // Import untuk formatCurrency
import 'form_transaction.dart'; // Import untuk navigasi ke form edit

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  String _selectedAggregation = 'Hari'; // Options: Hari, Bulan, Tahun

  // Logika Grouping Data (Sama seperti sebelumnya)
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
      if (_selectedAggregation == 'Hari') label = DateFormat('dd/MM/yyyy').format(dateObj);
      else if (_selectedAggregation == 'Bulan') label = DateFormat('MM/yyyy').format(dateObj);
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
    // Detail Screen menampilkan SEMUA data (dari _allTransactions di controller, tapi diakses via property yang sesuai)
    // Disini kita bisa akses _allTransactions jika controller mengeksposnya, atau gunakan logic load sendiri.
    // Asumsi: Detail Screen menampilkan semua histori tanpa filter "Bulan Ini" dari Home.
    // Jika ingin konsisten dengan Home, gunakan controller.transactions.
    // Tapi biasanya History menampilkan semua. Kita akan gunakan controller.transactions saja agar konsisten dengan filter global jika diinginkan,
    // ATAU kita bisa minta controller untuk memberikan semua data.
    // Untuk saat ini, kita gunakan data yang ada di controller.
    final groupedData = _processData(controller.transactions);

    return SafeArea(
      child: Column(
        children: [
          // Header Dropdown Aggregasi
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAggregation,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: ['Hari', 'Bulan', 'Tahun'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                    onChanged: (val) => setState(() => _selectedAggregation = val!),
                  ),
                ),
              ),
            ),
          ),

          // List Data
          Expanded(
            child: groupedData.isEmpty
                ? const Center(child: Text("Tidak ada data transaksi"))
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: groupedData.length,
              itemBuilder: (context, index) {
                return TransactionGroupCard(data: groupedData[index]);
              },
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
  const TransactionGroupCard({super.key, required this.data});

  @override
  State<TransactionGroupCard> createState() => _TransactionGroupCardState();
}

class _TransactionGroupCardState extends State<TransactionGroupCard> {
  bool _isExpanded = false;

  // --- LOGIKA GENERATE PDF ---
  Future<void> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();
    final transactions = widget.data.transactions;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text("Laporan Transaksi: ${widget.data.displayLabel}", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Tanggal', 'Nama', 'Kategori', 'Ket.', 'Tipe', 'Jumlah'],
              data: transactions.map((tx) {
                return [
                  DateFormat('dd/MM/yyyy').format(tx.date),
                  tx.name,
                  tx.categoryName ?? '-',
                  tx.description,
                  tx.isIncome ? 'Masuk' : 'Keluar',
                  formatCurrency(tx.amount),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.center,
                5: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 20),
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Total Pemasukan: ${formatCurrency(widget.data.totalIncome)}", style: const pw.TextStyle(color: PdfColors.green)),
                      pw.Text("Total Pengeluaran: ${formatCurrency(widget.data.totalExpense)}", style: const pw.TextStyle(color: PdfColors.red)),
                      pw.Divider(),
                      pw.Text("Net: ${formatCurrency(widget.data.totalIncome - widget.data.totalExpense)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  )
                ]
            )
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // --- LOGIKA POPUP DETAIL ---
  void _showDetailPopup(BuildContext context, TransactionModel tx) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text("Detail Transaksi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Divider(height: 30),

                      _buildDetailRow("Nama Transaksi", tx.name),
                      _buildDetailRow("Tanggal", DateFormat('dd MMMM yyyy').format(tx.date)),
                      _buildDetailRow(
                          "Nominal",
                          "Rp ${formatCurrency(tx.amount)}",
                          isBold: true,
                          color: tx.isIncome ? Colors.green : Colors.red
                      ),
                      _buildDetailRow("Kategori", tx.categoryName ?? '-'),
                      _buildDetailRow("Tipe", tx.isIncome ? "Pemasukan" : "Pengeluaran"),
                      _buildDetailRow("Keterangan", tx.description.isEmpty ? '-' : tx.description),

                      const SizedBox(height: 40),

                      // TOMBOL AKSI
                      Row(
                        children: [
                          // Tombol Hapus
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx); // Tutup popup dulu
                                // Konfirmasi Hapus
                                showDialog(
                                    context: context,
                                    builder: (dlgContext) => AlertDialog(
                                      title: const Text("Hapus Transaksi?"),
                                      content: const Text("Data yang dihapus tidak bisa dikembalikan."),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(dlgContext), child: const Text("Batal")),
                                        ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(dlgContext);
                                              Provider.of<TransactionController>(context, listen: false).deleteTransaction(tx.id!);
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaksi berhasil dihapus")));
                                            },
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                            child: const Text("Hapus")
                                        ),
                                      ],
                                    )
                                );
                              },
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              label: const Text("Hapus", style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: Colors.red)
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),

                          // Tombol Edit
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx); // Tutup popup
                                // Navigasi ke Form Edit dengan data transaksi
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AddTransactionForm(transactionToEdit: tx)),
                                );
                              },
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text("Edit"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              }
          );
        }
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14))),
          Expanded(
              flex: 3,
              child: Text(
                  value,
                  style: TextStyle(
                      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                      fontSize: isBold ? 16 : 14,
                      color: color ?? Colors.black87
                  )
              )
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            title: Text(widget.data.displayLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Masuk: ${formatCurrency(widget.data.totalIncome)}", style: const TextStyle(color: Colors.green, fontSize: 12)),
                Text("Keluar: ${formatCurrency(widget.data.totalExpense)}", style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // TOMBOL PDF
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                  tooltip: "Ekspor PDF",
                  onPressed: () => _generatePdf(context),
                ),
                Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
              ],
            ),
          ),
          if (_isExpanded)
            Column(
              children: widget.data.transactions.map((tx) {
                return ListTile(
                  dense: true,
                  // Trigger Popup Detail saat item diklik
                  onTap: () => _showDetailPopup(context, tx),
                  title: Text(tx.categoryName ?? 'Umum', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      tx.name.isNotEmpty ? tx.name : (tx.description.isNotEmpty ? tx.description : '-'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis
                  ),
                  trailing: Text(
                    "Rp ${formatCurrency(tx.amount)}",
                    style: TextStyle(color: tx.isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            )
        ],
      ),
    );
  }
}