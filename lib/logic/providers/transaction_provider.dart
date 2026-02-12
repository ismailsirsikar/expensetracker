import 'package:expensetracker/data/models/transaction_model.dart';
import 'package:expensetracker/data/repositories/transaction_repository.dart';
import 'package:flutter/foundation.dart';


class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _repo = TransactionRepository();
  List<TransactionModel> transactions = [];

  bool _initialized = false;
  bool get initialized => _initialized;

  Future<void> init() async {
    await _repo.init();
    await reload();
    _initialized = true;
    notifyListeners();
  }

  Future<void> reload() async {
    transactions = _repo.getAllTransactions();
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel tx) async {
    await _repo.addTransaction(tx);
    transactions.add(tx);
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    await _repo.updateTransaction(tx);
    final idx = transactions.indexWhere((t) => t.id == tx.id);
    if (idx != -1) transactions[idx] = tx;
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await _repo.deleteTransaction(id);
    transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  double totalIncomeForMonth(int year, int month) => _repo.getTotalIncomeForMonth(year, month);

  double totalExpenseForMonth(int year, int month) => _repo.getTotalExpenseForMonth(year, month);

  Map getCategoryTotalsForMonth(int year, int month) => _repo.getCategoryTotalsForMonth(year, month);
}
