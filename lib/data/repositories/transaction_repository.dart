import 'package:hive_flutter/hive_flutter.dart';

import '../models/transaction_model.dart';
import '../../core/constants/enums.dart';

class TransactionRepository {
  static const String transactionsBox = 'transactions';
  static const String categoriesBox = 'categories';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(transactionsBox);
    await Hive.openBox(categoriesBox);
  }

  Box get _txBox => Hive.box(transactionsBox);

  Future<void> addTransaction(TransactionModel tx) async {
    await _txBox.put(tx.id, tx.toMap());
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    await _txBox.put(tx.id, tx.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    await _txBox.delete(id);
  }

  List<TransactionModel> getAllTransactions() {
    final values = _txBox.values.cast<Map>().toList();
    return values.map((m) => TransactionModel.fromMap(Map<dynamic, dynamic>.from(m))).toList();
  }

  List<TransactionModel> getTransactionsForMonth(int year, int month) {
    return getAllTransactions()
        .where((t) => t.date.year == year && t.date.month == month)
        .toList();
  }

  double getTotalIncomeForMonth(int year, int month) {
    final list = getTransactionsForMonth(year, month)
        .where((t) => t.transactionType == TransactionType.income);
    return list.fold(0.0, (s, t) => s + t.amount);
  }

  double getTotalExpenseForMonth(int year, int month) {
    final list = getTransactionsForMonth(year, month)
        .where((t) => t.transactionType == TransactionType.expense);
    return list.fold(0.0, (s, t) => s + t.amount);
  }

  /// Returns totals grouped by `ExpenseCategory` for the given month.
  Map<ExpenseCategory, double> getCategoryTotalsForMonth(int year, int month) {
    final Map<ExpenseCategory, double> totals = {};
    final expenses = getTransactionsForMonth(year, month)
        .where((t) => t.transactionType == TransactionType.expense);
    for (var e in expenses) {
      totals[e.expenseCategory] = (totals[e.expenseCategory] ?? 0.0) + e.amount;
    }
    // Ensure all categories exist with zero if absent
    for (var c in ExpenseCategory.values) {
      totals.putIfAbsent(c, () => 0.0);
    }
    return totals;
  }

  /// Returns a map suitable for feeding pie chart: category -> percentage (0-100)
  Map<ExpenseCategory, double> getCategoryPercentagesForMonth(int year, int month) {
    final totals = getCategoryTotalsForMonth(year, month);
    final totalExpenses = totals.values.fold(0.0, (s, v) => s + v);
    if (totalExpenses == 0) return {for (var k in totals.keys) k: 0.0};
    return totals.map((k, v) => MapEntry(k, (v / totalExpenses) * 100));
  }
}


