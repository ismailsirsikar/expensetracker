import 'package:expensetracker/data/models/transaction_model.dart';
import 'package:hive/hive.dart';

class TransactionRepository {
  final Box<TransactionModel> box;

  TransactionRepository(this.box);

  void addTransaction(TransactionModel tx) {
    box.put(tx.id, tx);
  }

  void updateTransaction(TransactionModel tx) {
    box.put(tx.id, tx);
  }

  void deleteTransaction(String id) {
    box.delete(id);
  }

  List<TransactionModel> fetchAll() {
    return box.values.toList();
  }
}
