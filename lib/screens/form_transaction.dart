import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../controllers/transaction_controller.dart';
import '../models/models.dart';

class AddTransactionForm extends StatefulWidget {
  final TransactionModel? transactionToEdit;
  const AddTransactionForm({super.key, this.transactionToEdit});

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();

  // PERBAIKAN: Pastikan semua controller dideklarasikan
  bool _isIncome = true;
  final TextEditingController _nameController = TextEditingController(); // Tambahkan ini
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  DateTime? _selectedDate;
  int? _selectedCategoryId;
  bool get _isEditMode => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    // Memuat kategori saat pertama kali buka form
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());

    if (_isEditMode) {
      final tx = widget.transactionToEdit!;
      _isIncome = tx.isIncome;
      _selectedDate = tx.date;
      _selectedCategoryId = tx.categoryId;
      _dateController.text = DateFormat('dd/MM/yyyy').format(tx.date);
      _nameController.text = tx.name;
      _nominalController.text = tx.amount.toString();
      _descController.text = tx.description;
    } else {
      _selectedDate = DateTime.now();
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    }
  }

  void _loadCategories() {
    Provider.of<TransactionController>(context, listen: false).loadCategories(_isIncome);
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Logika simpan atau update transaksi di sini melalui controller
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? "Edit Transaksi" : "Tambah Transaksi")),
      body: Consumer<TransactionController>(
        builder: (context, controller, child) {
          List<DropdownMenuItem<int>> dropdownItems = controller.categories.map((cat) {
            return DropdownMenuItem<int>(
              value: cat.id,
              child: Text(cat.name),
            );
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Switch Pendapatan / Pengeluaran
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("Pendapatan"),
                          selected: _isIncome,
                          onSelected: (val) {
                            setState(() {
                              _isIncome = true;
                              _selectedCategoryId = null;
                            });
                            _loadCategories();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("Pengeluaran"),
                          selected: !_isIncome,
                          onSelected: (val) {
                            setState(() {
                              _isIncome = false;
                              _selectedCategoryId = null;
                            });
                            _loadCategories();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Nama Transaksi"),
                    validator: (v) => v!.isEmpty ? "Harus diisi" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _nominalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Nominal"),
                    validator: (v) => v!.isEmpty ? "Harus diisi" : null,
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    items: dropdownItems,
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                    decoration: const InputDecoration(labelText: "Kategori"),
                    validator: (v) => v == null ? "Pilih kategori" : null,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isIncome ? Colors.green : Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isEditMode ? "Update" : "Simpan"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class AddCategoryForm extends StatefulWidget {
  final bool initialIsIncome;
  const AddCategoryForm({super.key, required this.initialIsIncome});

  @override
  State<AddCategoryForm> createState() => _AddCategoryFormState();
}

class _AddCategoryFormState extends State<AddCategoryForm> {
  final _formKey = GlobalKey<FormState>();
  late bool _isIncome;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isIncome = widget.initialIsIncome;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Kategori")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nama Kategori"),
                validator: (v) => v!.isEmpty ? "Harus diisi" : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Logika simpan kategori
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Simpan Kategori",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}