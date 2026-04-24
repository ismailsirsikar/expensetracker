import 'package:expensetracker/data/models/transaction_model.dart';
import 'package:expensetracker/data/repositories/transaction_repository.dart';
import 'package:flutter/foundation.dart';


class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _repo;
  List<TransactionModel> transactions = [];

  TransactionProvider({TransactionRepository? repository}) : _repo = repository ?? TransactionRepository();

  bool _initialized = false;
  bool get initialized => _initialized;

  String? initError; // non-null when last init failed

  /// Initialize repository and load transactions. This method never leaves
  /// the provider in an un-initialized state — errors are recorded in
  /// `initError` and `_initialized` is set to true so the UI can show an
  /// error/retry state instead of an infinite loader.
  Future<void> init() async {
    initError = null;
    try {
      await _repo.init();
      await reload();
    } catch (e, st) {
      initError = e.toString();
      debugPrint('TransactionProvider.init() failed: $e\n$st');
      // Ensure transactions list is empty on failure
      transactions = [];
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> reload({int page = 1, int pageSize = 100}) async {
    await _repo.syncRemoteTransactions(page: page, pageSize: pageSize);
    transactions = _repo.getAllTransactions();
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel tx) async {
    final saved = await _repo.addTransaction(tx);
    transactions.add(saved);
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    final updated = await _repo.updateTransaction(tx);
    final idx = transactions.indexWhere((t) => t.id == updated.id);
    if (idx != -1) transactions[idx] = updated;
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
