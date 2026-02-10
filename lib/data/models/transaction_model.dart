
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
}
