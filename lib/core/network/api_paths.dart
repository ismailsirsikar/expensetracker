class ApiPaths {
  ApiPaths._();

  static const String baseUrl = 'https://localhost:7178/api';
  static const String authLogin = '$baseUrl/auth/login';
  static const String authRegister = '$baseUrl/auth/register';
  static const String authRefresh = '$baseUrl/auth/refresh';
  static const String transactions = '$baseUrl/transactions';
  static const String categories = '$baseUrl/categories';
  static const String reportsIncomeExpense = '$baseUrl/reports/income-vs-expense';
  static const String reportsCategorySummary =
      '$baseUrl/reports/category-summary';
  static const String reportsMonthlySummary =
      '$baseUrl/reports/monthly-summary';
}
