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
      'title': title,
      'amount': transactionType == TransactionType.expense ? -amount : amount,
      'category': subCategory,
      'type': transactionType == TransactionType.expense ? 'expense' : 'income',
      'date': date.toIso8601String(),
      'description': title,
    };
  }

  Map<String, dynamic> toMap() {
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

  static TransactionType _parseTransactionType(String? type) {
    if (type == null) return TransactionType.expense;
    return TransactionType.values.firstWhere(
      (e) => e.name.toLowerCase() == type.toLowerCase(),
      orElse: () => TransactionType.expense,
    );
  }

  static ExpenseCategory _parseExpenseCategory(
    String? category,
    TransactionType transactionType,
  ) {
    if (transactionType == TransactionType.income) {
      return ExpenseCategory.need;
    }
    if (category == null) return ExpenseCategory.need;

    final lower = category.toLowerCase();
    if (lower.contains('fd') || lower.contains('fixed deposit')) {
      return ExpenseCategory.fd;
    }
    if (lower.contains('sav') || lower.contains('investment')) {
      return ExpenseCategory.savings;
    }
    if (lower.contains('unwanted') || lower.contains('luxury')) {
      return ExpenseCategory.unwanted;
    }

    return ExpenseCategory.need;
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final transactionType = _parseTransactionType(
      (json['type'] as String?) ?? (json['transactionType'] as String?),
    );

    final dateString = (json['dateTime'] ?? json['date']) as String?;
    final rawAmount = (json['amount'] as num?)?.toDouble() ?? 0.0;
    final amount = rawAmount.abs();
    final rawCategory =
        (json['category'] as String?) ??
        (json['expenseCategory'] as String?) ??
        json['description'] as String?;
    final subCategory = json['subCategory'] as String? ?? rawCategory ?? '';
    final title =
        (json['title'] as String?) ??
        (json['description'] as String?) ??
        subCategory;

    return TransactionModel(
      id: json['id'] as String,
      title: title,
      amount: amount,
      date: DateTime.parse(dateString ?? DateTime.now().toIso8601String()),
      transactionType: transactionType,
      expenseCategory: _parseExpenseCategory(rawCategory, transactionType),
      subCategory: subCategory,
    );
  }

  factory TransactionModel.fromMap(Map<dynamic, dynamic> map) {
    return TransactionModel.fromJson(
      map.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}
