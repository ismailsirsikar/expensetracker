import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/transaction_model.dart';
import '../../core/constants/enums.dart';
import '../../logic/providers/transaction_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  TransactionType _txType = TransactionType.expense;
  ExpenseCategory _category = ExpenseCategory.need;
  String _subCategory = '';
  String _incomeSource = 'Salary';

  // Sub-category options per main category
  final Map<ExpenseCategory, List<String>> _subCategoryOptions = {
    ExpenseCategory.need: [
      'Food',
      'Breakfast',
      'Lunch',
      'Dinner',
      'Rent',
      'Travel',
      'Bills',
      'Utilities',
      'Groceries',
      'Medical',
      'Education',
      'Clothing',
      'Personal Care',
      'Health',
      'Medicine',
      'Other'
    ],
    ExpenseCategory.unwanted: [
      'Shopping',
      'Entertainment',
      'Coffee',
      'Snacks',
      'Subscriptions',
      'Movies',
      'Games',
      'Dining Out',
      'Hobbies',
      'Gadgets',
      'Books',
      'Gifts',
      'Vacations',
      'Video Games',
      'Other'
    ],
    ExpenseCategory.savings: [
      'Emergency',
      'Investment',
      'Other'
    ],
    ExpenseCategory.fd: [
      'Bank FD',
      'Other'
    ],
  };

  String? _selectedSubCategoryOption;

  Future<void> _pickDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (dt != null) setState(() => _date = dt);
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    // determine final subCategory
    String finalSub = _subCategory;
    if (_txType == TransactionType.expense) {
      if (_selectedSubCategoryOption != null && _selectedSubCategoryOption != 'Other') {
        finalSub = _selectedSubCategoryOption!;
      }
    } else {
      if (finalSub.isEmpty) finalSub = _incomeSource;
    }

    final tx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.trim()),
      date: _date,
      transactionType: _txType,
      // If this is income, set a placeholder expenseCategory and record the income source in subCategory
      expenseCategory: _txType == TransactionType.expense ? _category : ExpenseCategory.savings,
      subCategory: finalSub,
    );
    await provider.addTransaction(tx);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter amount';
                  final val = double.tryParse(v);
                  if (val == null || val <= 0) return 'Amount must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(_date.toLocal().toString().split(' ').first),
                trailing: IconButton(icon: const Icon(Icons.calendar_today), onPressed: _pickDate),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<TransactionType>(
                      title: const Text('Expense'),
                      value: TransactionType.expense,
                      groupValue: _txType,
                      onChanged: (v) => setState(() => _txType = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<TransactionType>(
                      title: const Text('Income'),
                      value: TransactionType.income,
                      groupValue: _txType,
                      onChanged: (v) => setState(() => _txType = v!),
                    ),
                  ),
                ],
              ),
              if (_txType == TransactionType.expense) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<ExpenseCategory>(
                  value: _category,
                  items: ExpenseCategory.values
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _category = v!;
                    // reset selected subcategory to the first option for the new category
                    final opts = _subCategoryOptions[_category]!;
                    _selectedSubCategoryOption = opts.isNotEmpty ? opts.first : null;
                    if (_selectedSubCategoryOption != 'Other') _subCategory = _selectedSubCategoryOption!;
                  }),
                  decoration: const InputDecoration(labelText: 'Expense Type'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedSubCategoryOption ?? _subCategoryOptions[_category]!.first,
                  items: _subCategoryOptions[_category]!
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedSubCategoryOption = v;
                    if (v != null && v != 'Other') _subCategory = v;
                    if (v == 'Other') _subCategory = '';
                  }),
                  decoration: const InputDecoration(labelText: 'Sub-category'),
                ),
                if (_selectedSubCategoryOption == 'Other' || (_selectedSubCategoryOption == null && _subCategory.isEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Custom sub-category'),
                      onChanged: (v) => _subCategory = v.trim(),
                    ),
                  ),
              ],
              if (_txType == TransactionType.income) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _incomeSource,
                  items: const [
                    DropdownMenuItem(value: 'Salary', child: Text('Salary')),
                    DropdownMenuItem(value: 'Pocket Money', child: Text('Pocket Money')),
                    DropdownMenuItem(value: 'Freelance', child: Text('Freelance')),
                    DropdownMenuItem(value: 'Gift', child: Text('Gift')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _incomeSource = v ?? 'Other'),
                  decoration: const InputDecoration(labelText: 'Income Source'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Note / Sub-category (optional)'),
                  onChanged: (v) => _subCategory = v.trim(),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
