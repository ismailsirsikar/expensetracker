import 'package:expensetracker/core/constants/enums.dart';
import 'package:expensetracker/data/models/transaction_model.dart';
import 'package:expensetracker/data/repositories/transaction_repository.dart';
import 'package:flutter/material.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionRepository repository;

  TransactionProvider(this.repository);

  List<TransactionModel> get transactions =>
      repository.fetchAll();

  void add(TransactionModel tx) {
    repository.addTransaction(tx);
    notifyListeners();
  }

  double get totalIncome =>
      transactions
          .where((t) => t.transactionType == TransactionType.income)
          .fold(0, (sum, t) => sum + t.amount);

  double get totalExpense =>
      transactions
          .where((t) => t.transactionType == TransactionType.expense)
          .fold(0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;
}
