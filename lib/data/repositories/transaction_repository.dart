import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../../core/constants/enums.dart';

class TransactionRepository {
  static const String transactionsBox = 'transactions';
  static const String categoriesBox = 'categories';

  final TransactionService? apiService;

  TransactionRepository({this.apiService});

  Future<void> init() async {
    try {
      // Hive is initialized from `main()`; avoid double-init here which can
      // cause platform/path races in some release environments.
      await Hive.openBox(transactionsBox);
      await Hive.openBox(categoriesBox);
    } catch (e, st) {
      debugPrint('TransactionRepository.init() failed: $e\n$st');
      rethrow;
    }
  }

  Box get _txBox => Hive.box(transactionsBox);

  Future<TransactionModel> addTransaction(TransactionModel tx) async {
    if (apiService != null) {
      final created = await apiService!.createTransaction(tx);
      await _txBox.put(created.id, created.toMap());
      return created;
    }

    await _txBox.put(tx.id, tx.toMap());
    return tx;
  }

  Future<TransactionModel> updateTransaction(TransactionModel tx) async {
    if (apiService != null) {
      final updated = await apiService!.updateTransaction(tx);
      await _txBox.put(updated.id, updated.toMap());
      return updated;
    }

    await _txBox.put(tx.id, tx.toMap());
    return tx;
  }

  Future<void> deleteTransaction(String id) async {
    if (apiService != null) {
      await apiService!.deleteTransaction(id);
    }
    await _txBox.delete(id);
  }

  List<TransactionModel> getAllTransactions() {
    final values = _txBox.values.cast<Map>().toList();
    return values
        .map((m) => TransactionModel.fromMap(Map<dynamic, dynamic>.from(m)))
        .toList();
  }

  Future<void> syncRemoteTransactions({
    int page = 1,
    int pageSize = 100,
  }) async {
    if (apiService == null) return;

    try {
      var currentPage = page;
      await _txBox.clear();

      while (true) {
        final remotePage = await apiService!.getTransactions(
          page: currentPage,
          pageSize: pageSize,
        );

        for (final tx in remotePage.items) {
          await _txBox.put(tx.id, tx.toMap());
        }

        if (currentPage >= remotePage.totalPages) {
          break;
        }

        currentPage += 1;
      }
    } catch (e, st) {
      debugPrint(
        'TransactionRepository.syncRemoteTransactions failed: $e\n$st',
      );
      rethrow;
    }
  }

  List<TransactionModel> getTransactionsForMonth(int year, int month) {
    return getAllTransactions()
        .where((t) => t.date.year == year && t.date.month == month)
        .toList();
  }

  double getTotalIncomeForMonth(int year, int month) {
    final list = getTransactionsForMonth(
      year,
      month,
    ).where((t) => t.transactionType == TransactionType.income);
    return list.fold(0.0, (s, t) => s + t.amount);
  }

  double getTotalExpenseForMonth(int year, int month) {
    final list = getTransactionsForMonth(
      year,
      month,
    ).where((t) => t.transactionType == TransactionType.expense);
    return list.fold(0.0, (s, t) => s + t.amount);
  }

  /// Returns totals grouped by `ExpenseCategory` for the given month.
  Map<ExpenseCategory, double> getCategoryTotalsForMonth(int year, int month) {
    final Map<ExpenseCategory, double> totals = {};
    final expenses = getTransactionsForMonth(
      year,
      month,
    ).where((t) => t.transactionType == TransactionType.expense);
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
  Map<ExpenseCategory, double> getCategoryPercentagesForMonth(
    int year,
    int month,
  ) {
    final totals = getCategoryTotalsForMonth(year, month);
    final totalExpenses = totals.values.fold(0.0, (s, v) => s + v);
    if (totalExpenses == 0) return {for (var k in totals.keys) k: 0.0};
    return totals.map((k, v) => MapEntry(k, (v / totalExpenses) * 100));
  }
}
