import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/transaction_controller.dart';
import '../models/models.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // PERBAIKAN: Deklarasi variabel yang sebelumnya 'Undefined'
  String _selectedAggregation = 'Hari';

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

      DateTime dateObj = DateTime.parse(entry.key.length == 4
          ? "${entry.key}-01-01"
          : (entry.key.length == 7 ? "${entry.key}-01" : entry.key));

      String label;
      if (_selectedAggregation == 'Hari') {
        label = DateFormat('dd MMM yyyy').format(dateObj);
      } else if (_selectedAggregation == 'Bulan') {
        label = DateFormat('MMMM yyyy').format(dateObj);
      } else {
        label = DateFormat('yyyy').format(dateObj);
      }

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

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Transaksi")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Agregasi: ", style: TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAggregation,
                      items: ['Hari', 'Bulan', 'Tahun'].map((String val) {
                        return DropdownMenuItem(value: val, child: Text(val));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedAggregation = val);
                      },
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
  _GroupedData({
    required this.sortKey,
    required this.displayLabel,
    required this.totalIncome,
    required this.totalExpense,
    required this.transactions
  });
}

class TransactionGroupCard extends StatefulWidget {
  final _GroupedData data;
  const TransactionGroupCard({super.key, required this.data});

  @override
  State<TransactionGroupCard> createState() => _TransactionGroupCardState();
}

class _TransactionGroupCardState extends State<TransactionGroupCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            title: Text(widget.data.displayLabel,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Masuk: ${widget.data.totalIncome} | Keluar: ${widget.data.totalExpense}"),
            trailing: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
          ),
          if (_isExpanded)
            Column(
              children: widget.data.transactions.map((tx) {
                return ListTile(
                  leading: Icon(tx.isIncome ? Icons.add_circle : Icons.remove_circle,
                      color: tx.isIncome ? Colors.green : Colors.red),
                  title: Text(tx.name),
                  trailing: Text("Rp ${tx.amount}"),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}