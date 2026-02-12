
import '../../core/constants/enums.dart';

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType transactionType;
  final ExpenseCategory expenseCategory;
  final String subCategory;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.transactionType,
    required this.expenseCategory,
    required this.subCategory,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'transactionType': transactionType.index,
      'expenseCategory': expenseCategory.index,
      'subCategory': subCategory,
    };
  }

  factory TransactionModel.fromMap(Map<dynamic, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      transactionType: TransactionType.values[map['transactionType'] as int],
      expenseCategory: ExpenseCategory.values[map['expenseCategory'] as int],
      subCategory: map['subCategory'] as String,
    );
  }
}
