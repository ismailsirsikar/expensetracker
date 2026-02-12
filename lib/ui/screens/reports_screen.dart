import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../logic/providers/transaction_provider.dart';
import '../../data/models/transaction_model.dart';
import '../../core/constants/enums.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  DateTime _startOfWeek(DateTime d) {
    return d.subtract(Duration(days: d.weekday - 1));
  }

  DateTime _endOfWeek(DateTime d) {
    return _startOfWeek(d).add(const Duration(days: 6));
  }

  List<TransactionModel> _filterByRange(List<TransactionModel> all, DateTime start, DateTime end) {
    return all.where((t) => !t.date.isBefore(start) && !t.date.isAfter(end)).toList();
  }

  double _sumByType(List<TransactionModel> list, TransactionType type) {
    return list.where((t) => t.transactionType == type).fold(0.0, (s, t) => s + t.amount);
  }

  Map<ExpenseCategory, double> _categoryTotals(List<TransactionModel> list) {
    final Map<ExpenseCategory, double> out = {};
    for (var c in ExpenseCategory.values) out[c] = 0.0;
    for (var t in list.where((t) => t.transactionType == TransactionType.expense)) {
      out[t.expenseCategory] = (out[t.expenseCategory] ?? 0) + t.amount;
    }
    return out;
  }

  Map<String, double> _subCategoryTotals(List<TransactionModel> list) {
    final Map<String, double> out = {};
    for (var t in list.where((t) => t.transactionType == TransactionType.expense)) {
      out[t.subCategory] = (out[t.subCategory] ?? 0) + t.amount;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final all = provider.transactions;
    final now = DateTime.now();
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // Weekly
    final weekStart = _startOfWeek(now);
    final weekEnd = _endOfWeek(now);
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = weekEnd.subtract(const Duration(days: 7));
    final weekTx = _filterByRange(all, weekStart, weekEnd);
    final lastWeekTx = _filterByRange(all, lastWeekStart, lastWeekEnd);
    final weeklyIncome = _sumByType(weekTx, TransactionType.income);
    final weeklyExpense = _sumByType(weekTx, TransactionType.expense);
    final weeklyBalance = weeklyIncome - weeklyExpense;
    final weeklyCategoryTotals = _categoryTotals(weekTx);

    // Monthly
    final monthStart = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthStart = DateTime(lastMonth.year, lastMonth.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final lastMonthEnd = DateTime(lastMonth.year, lastMonth.month + 1, 0);
    final monthTx = _filterByRange(all, monthStart, monthEnd);
    final lastMonthTx = _filterByRange(all, lastMonthStart, lastMonthEnd);
    final monthlyIncome = _sumByType(monthTx, TransactionType.income);
    final monthlyExpense = _sumByType(monthTx, TransactionType.expense);
    final monthlySavings = monthTx.where((t) => t.expenseCategory == ExpenseCategory.savings).fold(0.0, (s, t) => s + t.amount);
    final monthlyFD = monthTx.where((t) => t.expenseCategory == ExpenseCategory.fd).fold(0.0, (s, t) => s + t.amount);

    // Category analysis (top/bottom)
    final subTotals = _subCategoryTotals(all);
    final sortedSub = subTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final highest = sortedSub.isNotEmpty ? sortedSub.first : null;
    final lowest = sortedSub.isNotEmpty ? sortedSub.last : null;

    // Savings & health
    final incomeAll = all.where((t) => t.transactionType == TransactionType.income).fold(0.0, (s, t) => s + t.amount);
    final expenseAll = all.where((t) => t.transactionType == TransactionType.expense).fold(0.0, (s, t) => s + t.amount);
    final savingsAll = all.where((t) => t.expenseCategory == ExpenseCategory.savings).fold(0.0, (s, t) => s + t.amount);
    final savingsRate = incomeAll == 0 ? 0.0 : (savingsAll / incomeAll) * 100;
    final expenseRatio = incomeAll == 0 ? 0.0 : (expenseAll / incomeAll) * 100;

    // Comparison percentages
    double pctChange(double prev, double current) {
      if (prev == 0) return current == 0 ? 0.0 : 100.0;
      return ((current - prev) / prev) * 100;
    }

    final weeklySpendingChange = pctChange(_sumByType(lastWeekTx, TransactionType.expense), weeklyExpense);
    final monthlySpendingChange = pctChange(_sumByType(lastMonthTx, TransactionType.expense), monthlyExpense);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekly Report
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Weekly Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Period: ${DateFormat.yMMMd().format(weekStart)} - ${DateFormat.yMMMd().format(weekEnd)}'),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Income: ${fmt.format(weeklyIncome)}', style: const TextStyle(color: Colors.green)),
                    Text('Expense: ${fmt.format(weeklyExpense)}', style: const TextStyle(color: Colors.red)),
                    Text('Net: ${fmt.format(weeklyBalance)}'),
                  ]),
                  const SizedBox(height: 12),
                  // Category pie chart
                  SizedBox(
                    height: 180,
                    child: weeklyCategoryTotals.values.fold(0.0, (s, v) => s + v) == 0
                        ? const Center(child: Text('No weekly expenses'))
                        : PieChart(
                            PieChartData(
                              sections: weeklyCategoryTotals.entries.map((e) {
                                return PieChartSectionData(
                                  value: e.value,
                                  color: _colorForCategory(e.key),
                                  title: e.value > 0 ? '${(e.value).toStringAsFixed(0)}' : '',
                                );
                              }).toList(),
                              sectionsSpace: 2,
                              centerSpaceRadius: 24,
                            ),
                          ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // Monthly Report
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Monthly Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Period: ${DateFormat.yMMMM().format(now)}'),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Income: ${fmt.format(monthlyIncome)}', style: const TextStyle(color: Colors.green)),
                    Text('Expense: ${fmt.format(monthlyExpense)}', style: const TextStyle(color: Colors.red)),
                  ]),
                  const SizedBox(height: 8),
                  Text('Savings: ${fmt.format(monthlySavings)}  •  FD: ${fmt.format(monthlyFD)}'),
                  const SizedBox(height: 8),
                  // Bar chart comparing income vs expense this month vs last month
                  SizedBox(
                    height: 180,
                    child: BarChart(BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [
                          BarChartRodData(toY: monthlyIncome, color: Colors.green),
                        ]),
                        BarChartGroupData(x: 1, barRods: [
                          BarChartRodData(toY: monthlyExpense, color: Colors.red),
                        ]),
                        BarChartGroupData(x: 2, barRods: [
                          BarChartRodData(toY: _sumByType(lastMonthTx, TransactionType.income), color: Colors.green.withOpacity(0.5)),
                        ]),
                        BarChartGroupData(x: 3, barRods: [
                          BarChartRodData(toY: _sumByType(lastMonthTx, TransactionType.expense), color: Colors.red.withOpacity(0.5)),
                        ]),
                      ],
                      titlesData: FlTitlesData(show: true, bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta) {
                        switch (v.toInt()) {
                          case 0:
                            return const Text('This Income');
                          case 1:
                            return const Text('This Expense');
                          case 2:
                            return const Text('Last Income');
                          case 3:
                            return const Text('Last Expense');
                        }
                        return const Text('');
                      }))),
                      gridData: FlGridData(show: false),
                    )),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // Category Analysis
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Category Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (highest != null) Text('Highest spent: ${highest.key} — ${fmt.format(highest.value)}'),
                  if (lowest != null) Text('Lowest spent: ${lowest.key} — ${fmt.format(lowest.value)}'),
                  const SizedBox(height: 8),
                  Builder(builder: (_) {
                    final totals = _categoryTotals(all);
                    final unwanted = totals[ExpenseCategory.unwanted] ?? 0;
                    final totalExp = totals.values.fold(0.0, (s, v) => s + v);
                    final unwantedPct = totalExp == 0 ? 0.0 : (unwanted / totalExp) * 100;
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Unwanted spending: ${fmt.format(unwanted)} (${unwantedPct.toStringAsFixed(1)}%)'),
                      if (unwantedPct > 30) const Text('Warning: Unwanted spending > 30%', style: TextStyle(color: Colors.red)),
                    ]);
                  }),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // Savings & Health
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Savings & Financial Health', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Savings Rate: ${savingsRate.toStringAsFixed(1)}%'),
                  Text('Expense Ratio: ${expenseRatio.toStringAsFixed(1)}%'),
                  const SizedBox(height: 8),
                  Text('Weekly avg spending: ${fmt.format(_averageWeekly(all))}'),
                  Text('Monthly avg spending: ${fmt.format(_averageMonthly(all))}'),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // Comparisons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Comparisons', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Weekly spending change: ${weeklySpendingChange.toStringAsFixed(1)}%'),
                  Text('Monthly spending change: ${monthlySpendingChange.toStringAsFixed(1)}%'),
                ]),
              ),
            ),
            const SizedBox(height: 24),

            // Transaction list for week
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Transactions This Week', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (weekTx.isEmpty) const Text('No transactions this week')
                  else ...weekTx.map((t) => ListTile(
                        dense: true,
                        title: Text(t.title),
                        subtitle: Text('${t.subCategory} • ${DateFormat.yMMMd().format(t.date)}'),
                        trailing: Text((t.transactionType == TransactionType.expense ? '-' : '+') + fmt.format(t.amount), style: TextStyle(color: t.transactionType == TransactionType.expense ? Colors.red : Colors.green)),
                      ))
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _averageWeekly(List<TransactionModel> all) {
    if (all.isEmpty) return 0.0;
    final expenses = all.where((t) => t.transactionType == TransactionType.expense).toList();
    if (expenses.isEmpty) return 0.0;
    final first = expenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final weeks = (DateTime.now().difference(first).inDays / 7).ceil();
    final total = expenses.fold(0.0, (s, t) => s + t.amount);
    return total / (weeks == 0 ? 1 : weeks);
  }

  double _averageMonthly(List<TransactionModel> all) {
    if (all.isEmpty) return 0.0;
    final expenses = all.where((t) => t.transactionType == TransactionType.expense).toList();
    if (expenses.isEmpty) return 0.0;
    final first = expenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final months = ((DateTime.now().difference(first).inDays) / 30).ceil();
    final total = expenses.fold(0.0, (s, t) => s + t.amount);
    return total / (months == 0 ? 1 : months);
  }

  Color _colorForCategory(ExpenseCategory c) {
    switch (c) {
      case ExpenseCategory.need:
        return Colors.blue;
      case ExpenseCategory.unwanted:
        return Colors.red;
      case ExpenseCategory.savings:
        return Colors.green;
      case ExpenseCategory.fd:
        return Colors.orange;
    }
  }
}
