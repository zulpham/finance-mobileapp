import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Tambahkan ini untuk FilteringTextInputFormatter
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../controllers/transaction_controller.dart';
import '../models/models.dart';

// --- FORMATTER MANUAL UNTUK TITIK RIBUAN ---
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;

    // Hapus semua karakter selain angka
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Format menjadi ribuan dengan titik
    final formatter = NumberFormat.decimalPattern('id');
    String formattedText = formatter.format(int.parse(newText));

    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class AddTransactionForm extends StatefulWidget {
  final TransactionModel? transactionToEdit;
  const AddTransactionForm({super.key, this.transactionToEdit});

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isIncome = true;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  DateTime? _selectedDate;
  int? _selectedCategoryId;
  bool get _isEditMode => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final tx = widget.transactionToEdit!;
      _isIncome = tx.isIncome;
      _selectedDate = tx.date;
      _selectedCategoryId = tx.categoryId;
      _dateController.text = DateFormat('dd/MM/yyyy').format(tx.date);
      _nameController.text = tx.name;

      // Inisialisasi nominal dengan titik saat edit
      final formatter = NumberFormat.decimalPattern('id');
      _nominalController.text = formatter.format(tx.amount);

      _descController.text = tx.description;
    } else {
      _selectedDate = DateTime.now();
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
  }

  void _loadCategories() {
    Provider.of<TransactionController>(context, listen: false).loadCategories(_isIncome);
  }

  Widget _glassWrapper({required Widget child, bool isDark = false, EdgeInsets? margin}) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(isDark ? 35 : 120), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(isDark ? 30 : 20), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(20),
            color: isDark ? Colors.white.withAlpha(15) : Colors.white.withAlpha(130),
            child: child,
          ),
        ),
      ),
    );
  }

  InputDecoration _glassInput(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14),
      prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      filled: true,
      fillColor: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(15),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: Text(_isEditMode ? "Edit Transaksi" : "Tambah Transaksi", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned(
              top: -20, right: -20,
              child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withAlpha(isDark ? 35 : 55)))
          ),
          Positioned(
              bottom: 50, left: -30,
              child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purple.withAlpha(isDark ? 25 : 45)))
          ),

          Consumer<TransactionController>(
            builder: (context, controller, child) {
              List<DropdownMenuItem<int>> dropdownItems = controller.categories.map((cat) {
                return DropdownMenuItem<int>(value: cat.id, child: Text(cat.name));
              }).toList();
              dropdownItems.add(const DropdownMenuItem<int>(
                  value: -999,
                  child: Text("+ Tambah Kategori...", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
              ));

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _glassWrapper(
                        isDark: isDark,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  color: isDark ? Colors.black38 : Colors.black.withAlpha(15),
                                  borderRadius: BorderRadius.circular(15)
                              ),
                              child: Row(
                                children: [
                                  _buildTypeTab("Pemasukan", true, Colors.green),
                                  _buildTypeTab("Pengeluaran", false, Colors.red),
                                ],
                              ),
                            ),
                            const SizedBox(height: 25),
                            TextFormField(controller: _dateController, readOnly: true, decoration: _glassInput("Tanggal", Icons.calendar_today, isDark), onTap: _pickDate),
                            const SizedBox(height: 15),
                            TextFormField(controller: _nameController, decoration: _glassInput("Nama Transaksi", Icons.label_important_outline, isDark)),
                            const SizedBox(height: 15),

                            // --- TEXTFIELD NOMINAL DENGAN FORMAT TITIK ---
                            TextFormField(
                              controller: _nominalController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly, // Hanya angka
                                CurrencyInputFormatter(), // Custom formatter titik
                              ],
                              decoration: _glassInput("Nominal (Rp)", Icons.monetization_on_outlined, isDark),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                      _glassWrapper(
                        isDark: isDark,
                        child: Column(
                          children: [
                            DropdownButtonFormField<int>(
                              value: _selectedCategoryId,
                              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              decoration: _glassInput("Pilih Kategori", Icons.category_outlined, isDark),
                              items: dropdownItems,
                              onChanged: (val) => val == -999 ? _navigateToAddCategory() : setState(() => _selectedCategoryId = val),
                            ),
                            const SizedBox(height: 15),
                            TextFormField(controller: _descController, maxLines: 2, decoration: _glassInput("Keterangan Tambahan", Icons.notes, isDark)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isIncome ? Colors.green : Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 10,
                            shadowColor: (_isIncome ? Colors.green : Colors.red).withAlpha(100),
                          ),
                          child: Text(_isEditMode ? "Update Transaksi" : "Simpan Transaksi", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTab(String label, bool value, Color color) {
    bool isSelected = _isIncome == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTypeChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  void _onTypeChanged(bool value) {
    setState(() { _isIncome = value; _selectedCategoryId = null; });
    _loadCategories();
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked != null) setState(() { _selectedDate = picked; _dateController.text = DateFormat('dd/MM/yyyy').format(picked); });
  }

  void _navigateToAddCategory() async {
    setState(() => _selectedCategoryId = null);
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AddCategoryForm(initialIsIncome: _isIncome)));
    _loadCategories();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) return;
    final controller = Provider.of<TransactionController>(context, listen: false);

    // Pastikan titik dihapus sebelum dikirim ke database (parsing ke integer)
    String cleanAmount = _nominalController.text.replaceAll('.', '');

    final newTx = TransactionModel(
      id: _isEditMode ? widget.transactionToEdit!.id : null,
      name: _nameController.text,
      date: _selectedDate!,
      amount: int.parse(cleanAmount),
      description: _descController.text,
      isIncome: _isIncome,
      categoryId: _selectedCategoryId!,
    );
    _isEditMode ? await controller.updateTransaction(newTx) : await controller.addTransaction(newTx);
    if (mounted) Navigator.pop(context);
  }
}

// ---------------------------------------------------------------------------
// ADD CATEGORY FORM
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFE2E8F0),
      appBar: AppBar(title: const Text("Kategori Baru", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withAlpha(isDark ? 35 : 120), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: isDark ? Colors.black26 : Colors.black.withAlpha(10), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              _buildRadioTab("Masuk", true, Colors.green),
                              _buildRadioTab("Keluar", false, Colors.red),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: "Nama Kategori",
                            filled: true,
                            fillColor: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(15),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                          validator: (val) => (val == null || val.isEmpty) ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 35),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 5),
                            child: const Text("Simpan Kategori", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioTab(String label, bool val, Color color) {
    bool isSel = _isIncome == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isIncome = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSel ? color : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(label, style: TextStyle(color: isSel ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await Provider.of<TransactionController>(context, listen: false).addCategory(_nameController.text, _isIncome);
    if (mounted) Navigator.pop(context);
  }
}