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
  bool _isIncome = true;
  final TextEditingController _dateController = TextEditingController();
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
      _descController.text = tx.description;
    } else {
      _selectedDate = DateTime.now();
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    }
  }

  void _loadCategories() {
    Provider.of<TransactionController>(context, listen: false).loadCategories(_isIncome);
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            builder: (context, controller, child) {
              List<DropdownMenuItem<int>> dropdownItems = controller.categories.map((cat) {
              }).toList();
                  value: -999,

              return SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                          children: [
                                children: [
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),
                            const SizedBox(height: 15),

                            TextFormField(
                              controller: _nominalController,
                              keyboardType: TextInputType.number,
                            ),
                        ),
                            DropdownButtonFormField<int>(
                              value: _selectedCategoryId,
                              items: dropdownItems,
                            ),
                            const SizedBox(height: 15),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isIncome ? Colors.green : Colors.red,
                            foregroundColor: Colors.white,
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
          padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                            children: [
                          ),
                        ),
                        TextFormField(
                          controller: _nameController,
                            labelText: "Nama Kategori",
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
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