import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/transaction_model.dart';
import '../../core/constants/enums.dart';
import '../../logic/providers/transaction_provider.dart';

// ── Design system (keep in sync with home.dart) ──────────────────────────────
class _DS {
  static const bg = Color(0xFF0D1117);
  static const surface = Color(0xFF161B22);
  static const card = Color(0xFF1C2128);
  static const border = Color(0xFF30363D);
  static const textPrimary = Color(0xFFE6EDF3);
  static const textSecondary = Color(0xFF8B949E);
  static const green = Color(0xFF3FB950);
  static const red = Color(0xFFF85149);
  static const blue = Color(0xFF58A6FF);

  static const Map<ExpenseCategory, Color> catColor = {
    ExpenseCategory.need: Color(0xFF4FC3F7),
    ExpenseCategory.unwanted: Color(0xFFEF5350),
    ExpenseCategory.savings: Color(0xFF66BB6A),
    ExpenseCategory.fd: Color(0xFFFFB74D),
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

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  Set<ExpenseCategory> _selectedCategories = {};
  String _sortBy = 'date_desc'; // date_desc, date_asc, amount_desc, amount_asc
  TransactionType? _typeFilter; // null = all, expense, income

  List<TransactionModel> _getFiltered(List<TransactionModel> all) {
    var filtered = all.toList();

    // Filter by type
    if (_typeFilter != null) {
      filtered = filtered.where((t) => t.transactionType == _typeFilter).toList();
    }

    // Filter by date
    if (_startDate != null) {
      filtered = filtered.where((t) => !t.date.isBefore(_startDate!)).toList();
    }
    if (_endDate != null) {
      final endOfDay = _endDate!.add(const Duration(days: 1));
      filtered = filtered.where((t) => t.date.isBefore(endOfDay)).toList();
    }

    // Filter by category (only for expenses)
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((t) {
        if (t.transactionType == TransactionType.expense) {
          return _selectedCategories.contains(t.expenseCategory);
        }
        return false;
      }).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'date_asc':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'amount_desc':
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_asc':
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'date_desc':
      default:
        filtered.sort((a, b) => b.date.compareTo(a.date));
    }

    return filtered;
  }

  Future<void> _pickStartDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
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
    if (dt != null) setState(() => _startDate = dt);
  }

  Future<void> _pickEndDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
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
    if (dt != null) setState(() => _endDate = dt);
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _DS.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: _DS.border)),
        title: const Text('Delete transaction',
            style: TextStyle(color: _DS.textPrimary, fontSize: 16)),
        content: const Text('Are you sure you want to delete this transaction?',
            style: TextStyle(color: _DS.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: _DS.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: _DS.red)),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedCategories.clear();
      _typeFilter = null;
      _sortBy = 'date_desc';
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final filtered = _getFiltered(provider.transactions);
    final hasActiveFilters =
        _startDate != null || _endDate != null || _selectedCategories.isNotEmpty || _typeFilter != null;

    return Scaffold(
      backgroundColor: _DS.bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 110,
            pinned: true,
            backgroundColor: _DS.bg,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: _DS.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 52),
              title: const Text(
                'All Transactions',
                style: TextStyle(
                  color: _DS.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
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
        ],
        body: Column(
          children: [
            // ── Filter bar ────────────────────────────────────────────────────
            Container(
              color: _DS.surface,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                children: [
                  // Type filter
                  Row(
                    children: [
                      Expanded(
                        child: _FilterButton(
                          label: 'All Types',
                          isActive: _typeFilter == null,
                          onTap: () =>
                              setState(() => _typeFilter = null),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterButton(
                          label: 'Expenses',
                          isActive: _typeFilter == TransactionType.expense,
                          onTap: () => setState(
                              () => _typeFilter = TransactionType.expense),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterButton(
                          label: 'Income',
                          isActive: _typeFilter == TransactionType.income,
                          onTap: () => setState(
                              () => _typeFilter = TransactionType.income),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Category chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var cat in ExpenseCategory.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_selectedCategories.contains(cat)) {
                                    _selectedCategories.remove(cat);
                                  } else {
                                    _selectedCategories.add(cat);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: _selectedCategories.contains(cat)
                                      ? _DS.catColor[cat]!.withOpacity(0.2)
                                      : _DS.card,
                                  border: Border.all(
                                    color: _selectedCategories.contains(cat)
                                        ? _DS.catColor[cat]!
                                        : _DS.border,
                                  ),
                                ),
                                child: Text(
                                  _DS.catLabel[cat]!,
                                  style: TextStyle(
                                    color: _selectedCategories.contains(cat)
                                        ? _DS.catColor[cat]!
                                        : _DS.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date and sort controls
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickStartDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _DS.border),
                              color: _DS.card,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('From',
                                    style: TextStyle(
                                        color: _DS.textSecondary, fontSize: 10)),
                                Text(
                                  _startDate == null
                                      ? 'All'
                                      : DateFormat('d MMM').format(_startDate!),
                                  style: const TextStyle(
                                    color: _DS.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickEndDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _DS.border),
                              color: _DS.card,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('To',
                                    style: TextStyle(
                                        color: _DS.textSecondary, fontSize: 10)),
                                Text(
                                  _endDate == null
                                      ? 'Now'
                                      : DateFormat('d MMM').format(_endDate!),
                                  style: const TextStyle(
                                    color: _DS.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (hasActiveFilters)
                        GestureDetector(
                          onTap: _clearFilters,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: _DS.red.withOpacity(0.35)),
                              color: _DS.red.withOpacity(0.1),
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: _DS.red, size: 18),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Sort dropdown
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _DS.border),
                            color: _DS.card,
                          ),
                          child: DropdownButton<String>(
                            value: _sortBy,
                            isExpanded: true,
                            underline: const SizedBox(),
                            dropdownColor: _DS.card,
                            style: const TextStyle(
                              color: _DS.textPrimary,
                              fontSize: 12,
                            ),
                            onChanged: (val) {
                              if (val != null) setState(() => _sortBy = val);
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 'date_desc',
                                child: Text('Newest First'),
                              ),
                              DropdownMenuItem(
                                value: 'date_asc',
                                child: Text('Oldest First'),
                              ),
                              DropdownMenuItem(
                                value: 'amount_desc',
                                child: Text('Highest Amount'),
                              ),
                              DropdownMenuItem(
                                value: 'amount_asc',
                                child: Text('Lowest Amount'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _DS.border),
                          color: _DS.card,
                        ),
                        child: Text(
                          '${filtered.length}',
                          style: const TextStyle(
                            color: _DS.blue,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Transaction list ──────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(
                      hasFilters: hasActiveFilters,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final tx = filtered[idx];
                        return _TxCard(
                          tx: tx,
                          fmt: fmt,
                          onDelete: () async {
                            final confirm = await _confirmDelete(context);
                            if (confirm != true) return;
                            await provider.deleteTransaction(tx.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Transaction deleted'),
                                  backgroundColor: _DS.red.withOpacity(0.8),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter button ──────────────────────────────────────────────────────────────
class _FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isActive ? _DS.blue.withOpacity(0.15) : _DS.card,
            border: Border.all(
              color: isActive ? _DS.blue : _DS.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? _DS.blue : _DS.textSecondary,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      );
}

// ── Transaction card ──────────────────────────────────────────────────────────
class _TxCard extends StatelessWidget {
  final TransactionModel tx;
  final NumberFormat fmt;
  final VoidCallback onDelete;

  const _TxCard({
    required this.tx,
    required this.fmt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = tx.transactionType == TransactionType.expense;
    final color = isExpense
        ? (_DS.catColor[tx.expenseCategory] ?? _DS.red)
        : _DS.green;
    final icon = isExpense
        ? (_DS.catIcon[tx.expenseCategory] ?? Icons.receipt_rounded)
        : Icons.arrow_downward_rounded;

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _DS.red.withOpacity(0.15),
          border: Border.all(color: _DS.red.withOpacity(0.35)),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: _DS.red, size: 20),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _DS.surface,
          border: Border.all(color: _DS.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: color.withOpacity(0.15),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: const TextStyle(
                      color: _DS.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: color.withOpacity(0.12),
                        ),
                        child: Text(
                          tx.subCategory,
                          style: TextStyle(
                            color: color,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('d MMM, y').format(tx.date),
                        style:
                            const TextStyle(color: _DS.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${isExpense ? '−' : '+'}${fmt.format(tx.amount)}',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasFilters;

  const _EmptyState({required this.hasFilters});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters
                  ? Icons.filter_list_rounded
                  : Icons.receipt_rounded,
              size: 48,
              color: _DS.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'No transactions match filters'
                  : 'No transactions yet',
              style: const TextStyle(
                color: _DS.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
}
