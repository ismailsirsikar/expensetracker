import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/network/dio_client.dart';
import '../../core/network/token_storage.dart';
import '../../core/network/api_paths.dart';
import '../../core/constants/enums.dart';
import 'auth_service.dart';
import 'category_service.dart';
import 'report_service.dart';
import 'transaction_service.dart';
import '../models/transaction_model.dart';

Future<void> exampleUsage() async {
  final tokenStorage = InMemoryTokenStorage();

  final dio = Dio(BaseOptions(baseUrl: ApiPaths.baseUrl));
  final authService = AuthService(dio: dio, tokenStorage: tokenStorage);

  final client = DioClient(
    tokenStorage: tokenStorage,
    refreshTokenCallback: (refreshToken) async {
      return await authService.refreshToken();
    },
  );

  final categoryService = CategoryService(dio: client.dio);
  final reportService = ReportService(dio: client.dio);
  final transactionService = TransactionService(dio: client.dio);

  final authResponse = await authService.login(
    email: 'user@example.com',
    password: 'Password123',
  );
  debugPrint('Access token: ${authResponse.accessToken}');

  final categories = await categoryService.getCategories();
  debugPrint('Categories loaded: ${categories.length}');

  final newCategory = await categoryService.createCategory(
    'Travel',
    isMainCategory: false,
  );
  debugPrint('Created category: ${newCategory.categoryName}');

  final transactionPage = await transactionService.getTransactions(
    page: 1,
    pageSize: 20,
  );
  debugPrint(
    'Loaded ${transactionPage.items.length} transactions out of ${transactionPage.totalCount}',
  );

  final transaction = TransactionModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: 'Consulting fee',
    amount: 1200.00,
    date: DateTime.now(),
    transactionType: TransactionType.income,
    expenseCategory: ExpenseCategory.savings,
    subCategory: 'Services',
  );

  final createdTransaction = await transactionService.createTransaction(transaction);
  debugPrint('Created transaction id: ${createdTransaction.id}');

  final fetchedTransaction =
      await transactionService.getTransactionById(createdTransaction.id);
  debugPrint('Fetched transaction title: ${fetchedTransaction.title}');

  final incomeExpenseReport = await reportService.getIncomeVsExpense(
    startDate: DateTime.now().subtract(const Duration(days: 30)),
    endDate: DateTime.now(),
  );
  debugPrint('Net income for period: ${incomeExpenseReport.netIncome}');

  final categorySummary = await reportService.getCategorySummary(
    startDate: DateTime.now().subtract(const Duration(days: 30)),
    endDate: DateTime.now(),
  );
  debugPrint('Category summary count: ${categorySummary.length}');

  final monthlySummary = await reportService.getMonthlySummary(year: DateTime.now().year);
  debugPrint('Monthly summary entries: ${monthlySummary.length}');
}
