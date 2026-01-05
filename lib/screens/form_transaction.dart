import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../controllers/transaction_controller.dart';
import '../models/models.dart';

// ---------------------------------------------------------------------------
// HELPER: DIALOG KONFIRMASI
// ---------------------------------------------------------------------------
Future<bool> _showConfirmationDialog(BuildContext context, String title, String content) async {
  return await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text("Batal", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text("Ya, Simpan"),
        ),
      ],
    ),
  ) ?? false;
}

// ---------------------------------------------------------------------------
// FORM TAMBAH / EDIT TRANSAKSI
// ---------------------------------------------------------------------------

class AddTransactionForm extends StatefulWidget {
  // Parameter opsional untuk mode EDIT
  final TransactionModel? transactionToEdit;

  const AddTransactionForm({super.key, this.transactionToEdit});

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();

  bool _isIncome = true;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); // Controller Nama
  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  DateTime? _selectedDate;
  int? _selectedCategoryId;

  // Getter untuk mengecek apakah sedang mode edit
  bool get _isEditMode => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();

    // Inisialisasi Data
    if (_isEditMode) {
      // Mode Edit: Isi form dengan data lama
      final tx = widget.transactionToEdit!;
      _isIncome = tx.isIncome;
      _selectedDate = tx.date;
      _selectedCategoryId = tx.categoryId;

      _dateController.text = DateFormat('dd/MM/yyyy').format(tx.date);
      _nameController.text = tx.name;
      _nominalController.text = tx.amount.toString();
      _descController.text = tx.description;
    } else {
      // Mode Tambah: Default hari ini
      _selectedDate = DateTime.now();
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    }

    // Load kategori setelah build pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  void _loadCategories() {
    if (mounted) {
      Provider.of<TransactionController>(context, listen: false).loadCategories(_isIncome);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _nameController.dispose();
    _nominalController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onTypeChanged(bool? value) {
    if (value != null) {
      setState(() {
        _isIncome = value;
        _selectedCategoryId = null; // Reset kategori jika tipe berubah
      });
      _loadCategories();
    }
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // Navigasi ke Form Tambah Kategori
  void _navigateToAddCategory() async {
    setState(() {
      _selectedCategoryId = null;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCategoryForm(initialIsIncome: _isIncome),
      ),
    );

    if (mounted) {
      _loadCategories();
    }
  }

  Future<void> _submitForm() async {
    // 1. Validasi Form
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null || _selectedCategoryId == -999) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih kategori terlebih dahulu!")),
      );
      return;
    }

    // 2. Konfirmasi Dialog
    bool confirm = await _showConfirmationDialog(
        context,
        _isEditMode ? "Update Transaksi?" : "Simpan Transaksi?",
        "Pastikan data sudah benar."
    );

    if (!confirm) return;

    if (!mounted) return;
    final controller = Provider.of<TransactionController>(context, listen: false);

    // 3. Buat Object Model
    final newTx = TransactionModel(
      id: _isEditMode ? widget.transactionToEdit!.id : null, // ID diperlukan untuk update
      name: _nameController.text, // Nama Transaksi
      date: _selectedDate!,
      amount: int.parse(_nominalController.text.replaceAll('.', '')),
      description: _descController.text,
      isIncome: _isIncome,
      categoryId: _selectedCategoryId!,
    );

    // 4. Simpan ke Database via Controller
    if (_isEditMode) {
      await controller.updateTransaction(newTx);
    } else {
      await controller.addTransaction(newTx);
    }

    // 5. Feedback & Tutup Form
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditMode ? "Transaksi diperbarui!" : "Transaksi berhasil disimpan!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? "Edit Transaksi" : "Tambah Transaksi")),
      body: Consumer<TransactionController>(
        builder: (context, controller, child) {
          // Siapkan list dropdown kategori
          List<DropdownMenuItem<int>> dropdownItems = controller.categories.map((cat) {
            return DropdownMenuItem<int>(
              value: cat.id,
              child: Text(cat.name),
            );
          }).toList();

          // Tambahkan opsi "Tambah Kategori" di paling bawah
          dropdownItems.add(
            const DropdownMenuItem<int>(
              value: -999,
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Text("Tambah Kategori Baru...", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TIPE TRANSAKSI (Radio Button)
                  const Text("Tipe Transaksi", style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text("Pemasukan"),
                          value: true,
                          groupValue: _isIncome,
                          onChanged: _isEditMode ? null : _onTypeChanged, // Disable saat edit
                          activeColor: Colors.green,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text("Pengeluaran"),
                          value: false,
                          groupValue: _isIncome,
                          onChanged: _isEditMode ? null : _onTypeChanged,
                          activeColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // TANGGAL
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Tanggal",
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 15),

                  // NAMA TRANSAKSI (Fitur Baru)
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Nama Transaksi",
                      prefixIcon: Icon(Icons.label_outline),
                      border: OutlineInputBorder(),
                      hintText: "Contoh: Beli Makan Siang",
                    ),
                    validator: (val) => (val == null || val.isEmpty) ? 'Nama transaksi wajib diisi' : null,
                  ),
                  const SizedBox(height: 15),

                  // NOMINAL
                  TextFormField(
                    controller: _nominalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Nominal (Rp)",
                      prefixIcon: Icon(Icons.monetization_on_outlined),
                      border: OutlineInputBorder(),
                      hintText: "Contoh: 50000",
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Harus diisi';
                      if (int.tryParse(val.replaceAll('.', '')) == null) return 'Harus angka';
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // KATEGORI (Dropdown)
                  DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Kategori",
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: dropdownItems,
                    onChanged: (val) {
                      if (val == -999) {
                        _navigateToAddCategory();
                      } else {
                        setState(() => _selectedCategoryId = val);
                      }
                    },
                    hint: const Text("Pilih Kategori"),
                  ),
                  const SizedBox(height: 15),

                  // KETERANGAN
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: "Keterangan (Opsional)",
                      prefixIcon: Icon(Icons.notes),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 30),

                  // TOMBOL SIMPAN
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isIncome ? Colors.green : Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                          _isEditMode ? "Update Transaksi" : "Simpan Transaksi",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
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
// FORM TAMBAH KATEGORI BARU
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
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitCategory() async {
    if (!_formKey.currentState!.validate()) return;

    bool confirm = await _showConfirmationDialog(
        context,
        "Simpan Kategori?",
        "Kategori '${_nameController.text}' akan ditambahkan."
    );

    if (!confirm) return;

    if (!mounted) return;

    try {
      final controller = Provider.of<TransactionController>(context, listen: false);
      await controller.addCategory(_nameController.text, _isIncome);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kategori '${_nameController.text}' berhasil dibuat!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menyimpan kategori: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kategori Baru")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text("Pemasukan"),
                      value: true,
                      groupValue: _isIncome,
                      onChanged: (val) => setState(() => _isIncome = val!),
                      activeColor: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text("Pengeluaran"),
                      value: false,
                      groupValue: _isIncome,
                      onChanged: (val) => setState(() => _isIncome = val!),
                      activeColor: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nama Kategori",
                  border: OutlineInputBorder(),
                  hintText: "Misal: Jajan, Parkir, Bonus",
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Simpan Kategori", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}