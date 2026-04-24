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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'transactionType': transactionType.name,
      'expenseCategory': expenseCategory.name,
      'subCategory': subCategory,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      transactionType: TransactionType.values.firstWhere(
        (e) => e.name == json['transactionType'],
        orElse: () => TransactionType.expense,
      ),
      expenseCategory: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['expenseCategory'],
        orElse: () => ExpenseCategory.need,
      ),
      subCategory: json['subCategory'] as String,
    );
  }

  factory TransactionModel.fromMap(Map<dynamic, dynamic> map) {
    return TransactionModel.fromJson(
      map.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}
