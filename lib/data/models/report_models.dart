class IncomeExpenseReport {
  final double totalIncome;
  final double totalExpense;
  final double netAmount;

  IncomeExpenseReport({
    required this.totalIncome,
    required this.totalExpense,
    required this.netAmount,
  });

  double get netIncome => netAmount;

  factory IncomeExpenseReport.fromJson(Map<String, dynamic> json) {
    final income = (json['totalIncome'] as num?)?.toDouble() ?? 0.0;
    final expense = (json['totalExpense'] as num?)?.toDouble() ?? 0.0;
    final net = (json['netAmount'] as num?)?.toDouble() ?? income - expense;

    return IncomeExpenseReport(
      totalIncome: income,
      totalExpense: expense,
      netAmount: net,
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

class ReportDateRange {
  final DateTime from;
  final DateTime to;

  ReportDateRange({required this.from, required this.to});

  factory ReportDateRange.fromJson(Map<String, dynamic> json) {
    return ReportDateRange(
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
    );
  }
}

class ReportCreatedBy {
  final String id;
  final String name;

  ReportCreatedBy({required this.id, required this.name});

  factory ReportCreatedBy.fromJson(Map<String, dynamic> json) {
    return ReportCreatedBy(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class ReportFilters {
  final List<String> categories;
  final List<String> accounts;
  final double? minAmount;
  final double? maxAmount;

  ReportFilters({
    required this.categories,
    required this.accounts,
    this.minAmount,
    this.maxAmount,
  });

  factory ReportFilters.fromJson(Map<String, dynamic> json) {
    return ReportFilters(
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      accounts:
          (json['accounts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      minAmount: (json['minAmount'] as num?)?.toDouble(),
      maxAmount: (json['maxAmount'] as num?)?.toDouble(),
    );
  }
}

class ReportTotals {
  final double income;
  final double expense;
  final double net;

  ReportTotals({
    required this.income,
    required this.expense,
    required this.net,
  });

  factory ReportTotals.fromJson(Map<String, dynamic> json) {
    return ReportTotals(
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0.0,
      net: (json['net'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ReportTransactionPreview {
  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final String currency;
  final String category;

  ReportTransactionPreview({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.currency,
    required this.category,
  });

  factory ReportTransactionPreview.fromJson(Map<String, dynamic> json) {
    return ReportTransactionPreview(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }
}

class ReportItem {
  final String id;
  final String title;
  final ReportDateRange dateRange;
  final ReportCreatedBy createdBy;
  final DateTime createdAt;
  final ReportFilters filters;
  final ReportTotals totals;
  final int transactionsCount;
  final List<ReportTransactionPreview> transactionsPreview;
  final String selfLink;
  final String downloadLink;

  ReportItem({
    required this.id,
    required this.title,
    required this.dateRange,
    required this.createdBy,
    required this.createdAt,
    required this.filters,
    required this.totals,
    required this.transactionsCount,
    required this.transactionsPreview,
    required this.selfLink,
    required this.downloadLink,
  });

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    final links = json['links'] as Map<String, dynamic>? ?? {};

    return ReportItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      dateRange: ReportDateRange.fromJson(
        json['dateRange'] as Map<String, dynamic>,
      ),
      createdBy: ReportCreatedBy.fromJson(
        json['createdBy'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      filters: ReportFilters.fromJson(
        json['filters'] as Map<String, dynamic>? ?? {},
      ),
      totals: ReportTotals.fromJson(
        json['totals'] as Map<String, dynamic>? ?? {},
      ),
      transactionsCount: json['transactionsCount'] as int? ?? 0,
      transactionsPreview:
          (json['transactionsPreview'] as List<dynamic>?)
              ?.map(
                (item) => ReportTransactionPreview.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
      selfLink: links['self'] as String? ?? '',
      downloadLink: links['download'] as String? ?? '',
    );
  }
}
