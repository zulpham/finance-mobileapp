import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../controllers/transaction_controller.dart';
import '../models/models.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {

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

            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedAggregation,
                            isDense: true,
                            onChanged: (val) => setState(() => _selectedAggregation = val!),
                          ),
                        ),
                      ),
                  ),
                ),

                Expanded(
                  child: groupedData.isEmpty
                      ? const Center(child: Text("Tidak ada data transaksi"))
                      : ListView.builder(
                    itemCount: groupedData.length,
                    itemBuilder: (context, index) {
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
          pw.Table.fromTextArray(
          ),
        ],
      ),
    );
  }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Divider(height: 30),
              Row(
                children: [
                  Expanded(
                    onPressed: () {
    showDialog(
      context: context,
        title: const Text("Hapus Transaksi?"),
        actions: [
          ),

                );
            },
          ),
        ],
      ),
    );
  }

    return Padding(
      child: Row(
        children: [
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  title: Text(widget.data.displayLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    ],
                  ),
                ),
                if (_isExpanded)
                    dense: true,
            ),
          ),
      ),
    );
  }
}