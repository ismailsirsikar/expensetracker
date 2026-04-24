import 'package:dio/dio.dart';

import '../../core/constants/enums.dart';
import '../../core/network/api_paths.dart';
import '../models/paged_response_model.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final Dio dio;

  TransactionService({required this.dio});

  Future<PagedResponse<TransactionModel>> getTransactions({
    int page = 1,
    int pageSize = 20,
    TransactionType? transactionType,
    ExpenseCategory? expenseCategory,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (transactionType != null) 'transactionType': transactionType.name,
      if (expenseCategory != null) 'expenseCategory': expenseCategory.name,
      if (fromDate != null) 'fromDate': fromDate.toIso8601String(),
      if (toDate != null) 'toDate': toDate.toIso8601String(),
    };

    final response = await dio.get(
      ApiPaths.transactions,
      queryParameters: queryParameters,
    );
    return PagedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => TransactionModel.fromJson(json),
    );
  }

  Future<TransactionModel> getTransaction(String id) async {
    final response = await dio.get('${ApiPaths.transactions}/$id');
    return TransactionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TransactionModel> getTransactionById(String id) async {
    return getTransaction(id);
  }

  Future<TransactionModel> createTransaction(
    TransactionModel transaction,
  ) async {
    final response = await dio.post(
      ApiPaths.transactions,
      data: transaction.toJson(),
    );
    return TransactionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TransactionModel> updateTransaction(
    TransactionModel transaction,
  ) async {
    final response = await dio.put(
      '${ApiPaths.transactions}/${transaction.id}',
      data: transaction.toJson(),
    );
    return TransactionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTransaction(String id) async {
    await dio.delete('${ApiPaths.transactions}/$id');
  }
}
