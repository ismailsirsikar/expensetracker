import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/transaction_model.dart';
import '../../core/constants/enums.dart';
import '../../logic/providers/transaction_provider.dart';

// ── Design system (keep in sync with home.dart / reports_screen.dart) ─────────
class _DS {
  static const bg = Color(0xFF0D1117);
  static const surface = Color(0xFF161B22);
  static const card = Color(0xFF1C2128);
  static const border = Color(0xFF30363D);
  static const borderFocus = Color(0xFF58A6FF);
  static const textPrimary = Color(0xFFE6EDF3);
  static const textSecondary = Color(0xFF8B949E);
  static const textHint = Color(0xFF484F58);
  static const green = Color(0xFF3FB950);
  static const red = Color(0xFFF85149);
  static const blue = Color(0xFF58A6FF);

  static const Map<ExpenseCategory, Color> catColor = {
    ExpenseCategory.need: Color(0xFF4FC3F7),
    ExpenseCategory.unwanted: Color(0xFFEF5350),
    ExpenseCategory.savings: Color(0xFF66BB6A),
    ExpenseCategory.fd: Color(0xFFFFB74D),
  };

  static const Map<ExpenseCategory, List<Color>> catGradient = {
    ExpenseCategory.need: [Color(0xFF0288D1), Color(0xFF4FC3F7)],
    ExpenseCategory.unwanted: [Color(0xFFC62828), Color(0xFFEF9A9A)],
    ExpenseCategory.savings: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
    ExpenseCategory.fd: [Color(0xFFE65100), Color(0xFFFFB74D)],
  };

  static const Map<ExpenseCategory, IconData> catIcon = {
    ExpenseCategory.need: Icons.home_rounded,
    ExpenseCategory.unwanted: Icons.remove_shopping_cart_rounded,
    ExpenseCategory.savings: Icons.savings_rounded,
    ExpenseCategory.fd: Icons.account_balance_rounded,
  };

  static const Map<ExpenseCategory, String> catLabel = {
    ExpenseCategory.need: 'Needs',
    ExpenseCategory.unwanted: 'Unwanted',
    ExpenseCategory.savings: 'Savings',
    ExpenseCategory.fd: 'Fixed Deposit',
  };
}

// ─────────────────────────────────────────────────────────────────────────────

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _customSubCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  TransactionType _txType = TransactionType.expense;
  ExpenseCategory _category = ExpenseCategory.need;
  String _subCategory = '';
  String _incomeSource = 'Salary';
  String? _selectedSubOption;

  late AnimationController _anim;
  late Animation<double> _fade;

  static const Map<ExpenseCategory, List<String>> _subOptions = {
    ExpenseCategory.need: [
      'Food', 'Breakfast', 'Lunch', 'Dinner', 'Rent', 'Travel',
      'Bills', 'Utilities', 'Groceries', 'Medical', 'Education',
      'Clothing', 'Personal Care', 'Health', 'Medicine', 'Other'
    ],
    ExpenseCategory.unwanted: [
      'Shopping', 'Entertainment', 'Coffee', 'Snacks', 'Subscriptions',
      'Movies', 'Games', 'Dining Out', 'Hobbies', 'Gadgets',
      'Books', 'Gifts', 'Vacations', 'Video Games', 'Other'
    ],
    ExpenseCategory.savings: ['Emergency', 'Investment', 'Other'],
    ExpenseCategory.fd: ['Bank FD', 'Other'],
  };

  static const List<String> _incomeSources = [
    'Salary', 'Pocket Money', 'Freelance', 'Gift', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _selectedSubOption = _subOptions[_category]!.first;
    _subCategory = _selectedSubOption!;
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _customSubCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _DS.blue,
            onPrimary: _DS.textPrimary,
            surface: _DS.card,
            onSurface: _DS.textPrimary,
          ),
          dialogBackgroundColor: _DS.card,
        ),
        child: child!,
      ),
    );
    if (dt != null) setState(() => _date = dt);
  }

  void _onCategoryChanged(ExpenseCategory cat) {
    final opts = _subOptions[cat]!;
    setState(() {
      _category = cat;
      _selectedSubOption = opts.first;
      _subCategory = opts.first != 'Other' ? opts.first : '';
      _customSubCtrl.clear();
    });
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = Provider.of<TransactionProvider>(context, listen: false);

    String finalSub;
    if (_txType == TransactionType.expense) {
      finalSub = (_selectedSubOption == 'Other' || _selectedSubOption == null)
          ? _customSubCtrl.text.trim()
          : _selectedSubOption!;
    } else {
      finalSub = _subCategory.isEmpty ? _incomeSource : _subCategory;
    }

    final tx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.trim()),
      date: _date,
      transactionType: _txType,
      expenseCategory: _txType == TransactionType.expense
          ? _category
          : ExpenseCategory.savings,
      subCategory: finalSub,
    );
    await provider.addTransaction(tx);
    if (mounted) Navigator.pop(context);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DS.bg,
      body: FadeTransition(
        opacity: _fade,
        child: CustomScrollView(
          slivers: [
            // ── App bar ──────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: _DS.bg,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: _DS.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Add Transaction',
                style: TextStyle(
                  color: _DS.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF161B22), _DS.bg],
                    ),
                  ),
                ),
              ),
            ),

            // ── Form body ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Type toggle ──────────────────────────────────
                      _TypeToggle(
                        value: _txType,
                        onChange: (t) => setState(() => _txType = t),
                      ),
                      const SizedBox(height: 24),

                      // ── Amount ───────────────────────────────────────
                      _SectionLabel(label: 'Amount'),
                      const SizedBox(height: 8),
                      _AmountField(controller: _amountCtrl),
                      const SizedBox(height: 20),

                      // ── Title ────────────────────────────────────────
                      _SectionLabel(label: 'Title'),
                      const SizedBox(height: 8),
                      _DarkTextField(
                        controller: _titleCtrl,
                        hint: 'e.g. Grocery run, Monthly salary…',
                        icon: Icons.edit_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter a title'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // ── Date ─────────────────────────────────────────
                      _SectionLabel(label: 'Date'),
                      const SizedBox(height: 8),
                      _DatePickerRow(date: _date, onTap: _pickDate),
                      const SizedBox(height: 24),

                      // ── Expense-specific ─────────────────────────────
                      if (_txType == TransactionType.expense) ...[
                        _SectionLabel(label: 'Category'),
                        const SizedBox(height: 10),
                        _CategoryGrid(
                          selected: _category,
                          onChange: _onCategoryChanged,
                        ),
                        const SizedBox(height: 20),
                        _SectionLabel(label: 'Sub-category'),
                        const SizedBox(height: 8),
                        _SubCategoryPills(
                          options: _subOptions[_category]!,
                          selected: _selectedSubOption,
                          onChange: (v) => setState(() {
                            _selectedSubOption = v;
                            if (v != 'Other') {
                              _subCategory = v;
                              _customSubCtrl.clear();
                            } else {
                              _subCategory = '';
                            }
                          }),
                        ),
                        if (_selectedSubOption == 'Other') ...[
                          const SizedBox(height: 12),
                          _DarkTextField(
                            controller: _customSubCtrl,
                            hint: 'Describe the sub-category',
                            icon: Icons.label_outline_rounded,
                            validator: (v) =>
                                (_selectedSubOption == 'Other' &&
                                        (v == null || v.trim().isEmpty))
                                    ? 'Please enter a sub-category'
                                    : null,
                          ),
                        ],
                      ],

                      // ── Income-specific ──────────────────────────────
                      if (_txType == TransactionType.income) ...[
                        _SectionLabel(label: 'Source'),
                        const SizedBox(height: 8),
                        _SubCategoryPills(
                          options: _incomeSources,
                          selected: _incomeSource,
                          onChange: (v) =>
                              setState(() => _incomeSource = v),
                          accentColor: _DS.green,
                        ),
                        const SizedBox(height: 20),
                        _SectionLabel(label: 'Note (optional)'),
                        const SizedBox(height: 8),
                        _DarkTextField(
                          controller: _customSubCtrl,
                          hint: 'Any additional note…',
                          icon: Icons.notes_rounded,
                          onChanged: (v) => _subCategory = v.trim(),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // ── Save button ──────────────────────────────────
                      _SaveButton(
                        txType: _txType,
                        onTap: _save,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── Sub-widgets ───────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          color: _DS.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      );
}

// ── Type toggle ───────────────────────────────────────────────────────────────
class _TypeToggle extends StatelessWidget {
  final TransactionType value;
  final ValueChanged<TransactionType> onChange;

  const _TypeToggle({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _DS.surface,
        border: Border.all(color: _DS.border),
      ),
      child: Row(children: [
        Expanded(
          child: _ToggleOption(
            label: 'Expense',
            icon: Icons.arrow_upward_rounded,
            active: value == TransactionType.expense,
            activeColor: _DS.red,
            onTap: () => onChange(TransactionType.expense),
            isLeft: true,
          ),
        ),
        Expanded(
          child: _ToggleOption(
            label: 'Income',
            icon: Icons.arrow_downward_rounded,
            active: value == TransactionType.income,
            activeColor: _DS.green,
            onTap: () => onChange(TransactionType.income),
            isLeft: false,
          ),
        ),
      ]),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  final bool isLeft;

  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: active ? activeColor.withOpacity(0.15) : Colors.transparent,
          border: active
              ? Border.all(color: activeColor.withOpacity(0.5))
              : Border.all(color: Colors.transparent),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon,
              size: 16,
              color: active ? activeColor : _DS.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: active ? activeColor : _DS.textSecondary,
              fontSize: 14,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Amount field ──────────────────────────────────────────────────────────────
class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  const _AmountField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _DS.surface,
        border: Border.all(color: _DS.border),
      ),
      child: Row(children: [
        Container(
          width: 52,
          height: 56,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              bottomLeft: Radius.circular(15),
            ),
            color: _DS.card,
          ),
          child: const Center(
            child: Text('₹',
                style: TextStyle(
                    color: _DS.textSecondary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const VerticalDivider(color: _DS.border, width: 1, thickness: 1),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
            ],
            style: const TextStyle(
              color: _DS.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            decoration: const InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(
                  color: _DS.textHint,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter amount';
              final val = double.tryParse(v);
              if (val == null || val <= 0) return 'Amount must be > 0';
              return null;
            },
          ),
        ),
      ]),
    );
  }
}

// ── Generic dark text field ───────────────────────────────────────────────────
class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const _DarkTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: _DS.textPrimary, fontSize: 14),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: _DS.textHint, fontSize: 14),
        prefixIcon: Icon(icon, color: _DS.textSecondary, size: 18),
        filled: true,
        fillColor: _DS.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _DS.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: _DS.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: _DS.red.withOpacity(0.7)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _DS.red, width: 1.5),
        ),
        errorStyle: const TextStyle(color: _DS.red, fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ── Date picker row ───────────────────────────────────────────────────────────
class _DatePickerRow extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerRow({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${_weekday(date.weekday)}, ${date.day} ${_month(date.month)} ${date.year}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _DS.surface,
          border: Border.all(color: _DS.border),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded,
              color: _DS.textSecondary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(formatted,
                style: const TextStyle(
                    color: _DS.textPrimary, fontSize: 14)),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: _DS.textSecondary, size: 20),
        ]),
      ),
    );
  }

  String _weekday(int w) => const [
        '', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
      ][w];

  String _month(int m) => const [
        '',
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

// ── Category grid ─────────────────────────────────────────────────────────────
class _CategoryGrid extends StatelessWidget {
  final ExpenseCategory selected;
  final ValueChanged<ExpenseCategory> onChange;

  const _CategoryGrid(
      {required this.selected, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ExpenseCategory.values.map((cat) {
        final isSelected = cat == selected;
        final color = _DS.catColor[cat]!;
        final gradient = _DS.catGradient[cat]!;

        return Expanded(
          child: GestureDetector(
            onTap: () => onChange(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isSelected
                    ? color.withOpacity(0.15)
                    : _DS.surface,
                border: Border.all(
                  color: isSelected
                      ? color.withOpacity(0.6)
                      : _DS.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected
                          ? LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : _DS.card,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Icon(
                      _DS.catIcon[cat]!,
                      size: 15,
                      color:
                          isSelected ? Colors.white : _DS.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _DS.catLabel[cat]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? color : _DS.textSecondary,
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Sub-category / source pills ───────────────────────────────────────────────
class _SubCategoryPills extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onChange;
  final Color accentColor;

  const _SubCategoryPills({
    required this.options,
    required this.selected,
    required this.onChange,
    this.accentColor = _DS.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return GestureDetector(
          onTap: () => onChange(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isSelected
                  ? accentColor.withOpacity(0.15)
                  : _DS.surface,
              border: Border.all(
                color: isSelected
                    ? accentColor.withOpacity(0.6)
                    : _DS.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              opt,
              style: TextStyle(
                color: isSelected ? accentColor : _DS.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Save button ───────────────────────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final TransactionType txType;
  final VoidCallback onTap;

  const _SaveButton({required this.txType, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isExpense = txType == TransactionType.expense;
    final color = isExpense ? _DS.red : _DS.green;
    final gradColors = isExpense
        ? [const Color(0xFF7F1D1D), const Color(0xFFF85149)]
        : [const Color(0xFF1B5E20), const Color(0xFF3FB950)];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: gradColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            isExpense
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            isExpense ? 'Save Expense' : 'Save Income',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ]),
      ),
    );
  }
}