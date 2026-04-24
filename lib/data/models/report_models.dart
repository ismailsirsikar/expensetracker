class IncomeExpenseReport {
  final double totalIncome;
  final double totalExpense;
  final double netIncome;

  IncomeExpenseReport({
    required this.totalIncome,
    required this.totalExpense,
    required this.netIncome,
  });

  factory IncomeExpenseReport.fromJson(Map<String, dynamic> json) {
    final income = (json['totalIncome'] as num?)?.toDouble() ?? 0.0;
    final expense = (json['totalExpense'] as num?)?.toDouble() ?? 0.0;
    return IncomeExpenseReport(
      totalIncome: income,
      totalExpense: expense,
      netIncome: income - expense,
    );
  }
}

class CategorySummaryReport {
  final String category;
  final double amount;
  final double percentage;

  CategorySummaryReport({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  factory CategorySummaryReport.fromJson(Map<String, dynamic> json) {
    return CategorySummaryReport(
      category: json['category'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MonthlySummaryReport {
  final String period;
  final double totalIncome;
  final double totalExpense;
  final double netAmount;

  MonthlySummaryReport({
    required this.period,
    required this.totalIncome,
    required this.totalExpense,
    required this.netAmount,
  });

  factory MonthlySummaryReport.fromJson(Map<String, dynamic> json) {
    return MonthlySummaryReport(
      period: json['period'] as String? ?? '',
      totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
