import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../logic/providers/transaction_provider.dart';
import '../../data/models/transaction_model.dart';
import '../../core/constants/enums.dart';

// ── Palette & styles shared across all widgets ────────────────────────────────
class _DS {
  static const bg = Color(0xFF0D1117);
  static const surface = Color(0xFF161B22);
  static const card = Color(0xFF1C2128);
  static const border = Color(0xFF30363D);
  static const textPrimary = Color(0xFFE6EDF3);
  static const textSecondary = Color(0xFF8B949E);
  static const green = Color(0xFF3FB950);
  static const red = Color(0xFFF85149);
  static const blue = Color(0xFF58A6FF);
  static const orange = Color(0xFFD29922);

  static const Map<ExpenseCategory, Color> catColor = {
    ExpenseCategory.need: Color(0xFF4FC3F7),
    ExpenseCategory.unwanted: Color(0xFFEF5350),
    ExpenseCategory.savings: Color(0xFF66BB6A),
    ExpenseCategory.fd: Color(0xFFFFB74D),
  };

  static const Map<ExpenseCategory, List<Color>> catGradient = {
    ExpenseCategory.need: [Color(0xFF0288D1), Color(0xFF4FC3F7)],
    ExpenseCategory.unwanted: [Color(0xFFC62828), Color(0xFFEF9A9A)],
    ExpenseCategory.savings: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
    ExpenseCategory.fd: [Color(0xFFE65100), Color(0xFFFFB74D)],
  };

  static const Map<ExpenseCategory, IconData> catIcon = {
    ExpenseCategory.need: Icons.home_rounded,
    ExpenseCategory.unwanted: Icons.remove_shopping_cart_rounded,
    ExpenseCategory.savings: Icons.savings_rounded,
    ExpenseCategory.fd: Icons.account_balance_rounded,
  };

  static const Map<ExpenseCategory, String> catLabel = {
    ExpenseCategory.need: 'Needs',
    ExpenseCategory.unwanted: 'Unwanted',
    ExpenseCategory.savings: 'Savings',
    ExpenseCategory.fd: 'Fixed Deposit',
  };
}

// ─────────────────────────────────────────────────────────────────────────────

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  DateTime _startOfWeek(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));
  DateTime _endOfWeek(DateTime d) =>
      _startOfWeek(d).add(const Duration(days: 6));

  List<TransactionModel> _filterByRange(
      List<TransactionModel> all, DateTime start, DateTime end) {
    return all
        .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
        .toList();
  }

  double _sumByType(List<TransactionModel> list, TransactionType type) =>
      list
          .where((t) => t.transactionType == type)
          .fold(0.0, (s, t) => s + t.amount);

  Map<ExpenseCategory, double> _categoryTotals(List<TransactionModel> list) {
    final out = {for (var c in ExpenseCategory.values) c: 0.0};
    for (var t
        in list.where((t) => t.transactionType == TransactionType.expense)) {
      out[t.expenseCategory] = (out[t.expenseCategory] ?? 0) + t.amount;
    }
    return out;
  }

  Map<String, double> _subCategoryTotals(List<TransactionModel> list) {
    final out = <String, double>{};
    for (var t
        in list.where((t) => t.transactionType == TransactionType.expense)) {
      out[t.subCategory] = (out[t.subCategory] ?? 0) + t.amount;
    }
    return out;
  }

  double _pctChange(double prev, double current) {
    if (prev == 0) return current == 0 ? 0.0 : 100.0;
    return ((current - prev) / prev) * 100;
  }

  double _averageWeekly(List<TransactionModel> all) {
    final expenses =
        all.where((t) => t.transactionType == TransactionType.expense).toList();
    if (expenses.isEmpty) return 0.0;
    final first =
        expenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final weeks = (DateTime.now().difference(first).inDays / 7).ceil();
    return expenses.fold(0.0, (s, t) => s + t.amount) /
        (weeks == 0 ? 1 : weeks);
  }

  double _averageMonthly(List<TransactionModel> all) {
    final expenses =
        all.where((t) => t.transactionType == TransactionType.expense).toList();
    if (expenses.isEmpty) return 0.0;
    final first =
        expenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final months =
        (DateTime.now().difference(first).inDays / 30).ceil();
    return expenses.fold(0.0, (s, t) => s + t.amount) /
        (months == 0 ? 1 : months);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final all = provider.transactions;
    final now = DateTime.now();
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // ── Weekly data ──────────────────────────────────────────────────────────
    final weekStart = _startOfWeek(now);
    final weekEnd = _endOfWeek(now);
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = weekEnd.subtract(const Duration(days: 7));
    final weekTx = _filterByRange(all, weekStart, weekEnd);
    final lastWeekTx = _filterByRange(all, lastWeekStart, lastWeekEnd);
    final weeklyIncome = _sumByType(weekTx, TransactionType.income);
    final weeklyExpense = _sumByType(weekTx, TransactionType.expense);
    final weeklyBalance = weeklyIncome - weeklyExpense;
    final weeklyCatTotals = _categoryTotals(weekTx);
    final weeklySpendingChange =
        _pctChange(_sumByType(lastWeekTx, TransactionType.expense), weeklyExpense);

    // ── Monthly data ─────────────────────────────────────────────────────────
    final monthStart = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthStart = DateTime(lastMonth.year, lastMonth.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final lastMonthEnd = DateTime(lastMonth.year, lastMonth.month + 1, 0);
    final monthTx = _filterByRange(all, monthStart, monthEnd);
    final lastMonthTx = _filterByRange(all, lastMonthStart, lastMonthEnd);
    final monthlyIncome = _sumByType(monthTx, TransactionType.income);
    final monthlyExpense = _sumByType(monthTx, TransactionType.expense);
    final monthlySavings = monthTx
        .where((t) => t.expenseCategory == ExpenseCategory.savings)
        .fold(0.0, (s, t) => s + t.amount);
    final monthlyFD = monthTx
        .where((t) => t.expenseCategory == ExpenseCategory.fd)
        .fold(0.0, (s, t) => s + t.amount);
    final monthlyCatTotals = _categoryTotals(monthTx);
    final monthlySpendingChange = _pctChange(
        _sumByType(lastMonthTx, TransactionType.expense), monthlyExpense);
    final lastMonthlyIncome =
        _sumByType(lastMonthTx, TransactionType.income);
    final lastMonthlyExpense =
        _sumByType(lastMonthTx, TransactionType.expense);

    // ── Overall health ───────────────────────────────────────────────────────
    final incomeAll = all
        .where((t) => t.transactionType == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final expenseAll = all
        .where((t) => t.transactionType == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    final savingsAll = all
        .where((t) => t.expenseCategory == ExpenseCategory.savings)
        .fold(0.0, (s, t) => s + t.amount);
    final savingsRate =
        incomeAll == 0 ? 0.0 : (savingsAll / incomeAll) * 100;
    final expenseRatio =
        incomeAll == 0 ? 0.0 : (expenseAll / incomeAll) * 100;

    final subTotals = _subCategoryTotals(all);
    final sortedSub = subTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final highest = sortedSub.isNotEmpty ? sortedSub.first : null;
    final lowest = sortedSub.isNotEmpty ? sortedSub.last : null;

    final allCatTotals = _categoryTotals(all);
    final unwanted = allCatTotals[ExpenseCategory.unwanted] ?? 0;
    final totalExp = allCatTotals.values.fold(0.0, (s, v) => s + v);
    final unwantedPct = totalExp == 0 ? 0.0 : (unwanted / totalExp) * 100;

    return Scaffold(
      backgroundColor: _DS.bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 110,
            pinned: true,
            backgroundColor: _DS.bg,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: _DS.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 52),
              title: const Text(
                'Reports',
                style: TextStyle(
                  color: _DS.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF161B22), _DS.bg],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 40,
                decoration: BoxDecoration(
                  color: _DS.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _DS.border),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _DS.card,
                    border: Border.all(color: _DS.border),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: _DS.textPrimary,
                  unselectedLabelColor: _DS.textSecondary,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Weekly'),
                    Tab(text: 'Monthly'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            // ── WEEKLY TAB ──────────────────────────────────────────────────
            _WeeklyTab(
              weekStart: weekStart,
              weekEnd: weekEnd,
              income: weeklyIncome,
              expense: weeklyExpense,
              balance: weeklyBalance,
              spendingChange: weeklySpendingChange,
              catTotals: weeklyCatTotals,
              transactions: weekTx,
              fmt: fmt,
              avgWeekly: _averageWeekly(all),
            ),

            // ── MONTHLY TAB ─────────────────────────────────────────────────
            _MonthlyTab(
              now: now,
              income: monthlyIncome,
              expense: monthlyExpense,
              savings: monthlySavings,
              fd: monthlyFD,
              spendingChange: monthlySpendingChange,
              catTotals: monthlyCatTotals,
              lastIncome: lastMonthlyIncome,
              lastExpense: lastMonthlyExpense,
              savingsRate: savingsRate,
              expenseRatio: expenseRatio,
              avgMonthly: _averageMonthly(all),
              highest: highest,
              lowest: lowest,
              unwanted: unwanted,
              unwantedPct: unwantedPct,
              fmt: fmt,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Weekly Tab ────────────────────────────────────────────────────────────────
class _WeeklyTab extends StatelessWidget {
  final DateTime weekStart, weekEnd;
  final double income, expense, balance, spendingChange, avgWeekly;
  final Map<ExpenseCategory, double> catTotals;
  final List<TransactionModel> transactions;
  final NumberFormat fmt;

  const _WeeklyTab({
    required this.weekStart,
    required this.weekEnd,
    required this.income,
    required this.expense,
    required this.balance,
    required this.spendingChange,
    required this.catTotals,
    required this.transactions,
    required this.fmt,
    required this.avgWeekly,
  });

  @override
  Widget build(BuildContext context) {
    final total = catTotals.values.fold(0.0, (s, v) => s + v);
    final period =
        '${DateFormat('d MMM').format(weekStart)} – ${DateFormat('d MMM').format(weekEnd)}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // Period label
        Text(period,
            style: const TextStyle(
                color: _DS.textSecondary, fontSize: 13, letterSpacing: 0.2)),
        const SizedBox(height: 12),

        // ── KPI row ────────────────────────────────────────────────────────
        Row(children: [
          Expanded(
              child: _KpiCard(
                  label: 'Income',
                  value: fmt.format(income),
                  icon: Icons.arrow_downward_rounded,
                  color: _DS.green)),
          const SizedBox(width: 10),
          Expanded(
              child: _KpiCard(
                  label: 'Expenses',
                  value: fmt.format(expense),
                  icon: Icons.arrow_upward_rounded,
                  color: _DS.red)),
        ]),
        const SizedBox(height: 10),
        _NetBalanceCard(balance: balance, fmt: fmt, change: spendingChange),
        const SizedBox(height: 20),

        // ── Pie chart ─────────────────────────────────────────────────────
        _SectionHeader(title: 'Category Breakdown'),
        const SizedBox(height: 12),
        total == 0
            ? _EmptyCard(message: 'No expenses this week')
            : _PieCard(catTotals: catTotals, total: total, fmt: fmt),
        const SizedBox(height: 20),

        // ── Average ───────────────────────────────────────────────────────
        _StatRow(
            label: 'Weekly avg spending',
            value: fmt.format(avgWeekly),
            icon: Icons.show_chart_rounded),
        const SizedBox(height: 20),

        // ── Transactions ──────────────────────────────────────────────────
        _SectionHeader(title: 'Transactions This Week'),
        const SizedBox(height: 12),
        transactions.isEmpty
            ? _EmptyCard(message: 'No transactions this week')
            : Column(
                children: transactions
                    .map((t) => _TxTile(tx: t, fmt: fmt))
                    .toList()),
      ],
    );
  }
}

// ── Monthly Tab ───────────────────────────────────────────────────────────────
class _MonthlyTab extends StatelessWidget {
  final DateTime now;
  final double income, expense, savings, fd, spendingChange;
  final double lastIncome, lastExpense;
  final double savingsRate, expenseRatio, avgMonthly;
  final double unwanted, unwantedPct;
  final Map<ExpenseCategory, double> catTotals;
  final MapEntry<String, double>? highest;
  final MapEntry<String, double>? lowest;
  final NumberFormat fmt;

  const _MonthlyTab({
    required this.now,
    required this.income,
    required this.expense,
    required this.savings,
    required this.fd,
    required this.spendingChange,
    required this.catTotals,
    required this.lastIncome,
    required this.lastExpense,
    required this.savingsRate,
    required this.expenseRatio,
    required this.avgMonthly,
    required this.highest,
    required this.lowest,
    required this.unwanted,
    required this.unwantedPct,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final total = catTotals.values.fold(0.0, (s, v) => s + v);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(DateFormat('MMMM yyyy').format(now),
            style: const TextStyle(
                color: _DS.textSecondary, fontSize: 13, letterSpacing: 0.2)),
        const SizedBox(height: 12),

        // ── KPI row ────────────────────────────────────────────────────────
        Row(children: [
          Expanded(
              child: _KpiCard(
                  label: 'Income',
                  value: fmt.format(income),
                  icon: Icons.arrow_downward_rounded,
                  color: _DS.green)),
          const SizedBox(width: 10),
          Expanded(
              child: _KpiCard(
                  label: 'Expenses',
                  value: fmt.format(expense),
                  icon: Icons.arrow_upward_rounded,
                  color: _DS.red)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _KpiCard(
                  label: 'Savings',
                  value: fmt.format(savings),
                  icon: Icons.savings_rounded,
                  color: _DS.catColor[ExpenseCategory.savings]!)),
          const SizedBox(width: 10),
          Expanded(
              child: _KpiCard(
                  label: 'Fixed Deposit',
                  value: fmt.format(fd),
                  icon: Icons.account_balance_rounded,
                  color: _DS.catColor[ExpenseCategory.fd]!)),
        ]),
        const SizedBox(height: 20),

        // ── Bar chart: this vs last month ─────────────────────────────────
        _SectionHeader(title: 'This vs Last Month'),
        const SizedBox(height: 12),
        _ComparisonBarCard(
          thisIncome: income,
          thisExpense: expense,
          lastIncome: lastIncome,
          lastExpense: lastExpense,
          fmt: fmt,
          spendingChange: spendingChange,
        ),
        const SizedBox(height: 20),

        // ── Category breakdown pie ─────────────────────────────────────────
        _SectionHeader(title: 'Category Breakdown'),
        const SizedBox(height: 12),
        total == 0
            ? _EmptyCard(message: 'No expenses this month')
            : _PieCard(catTotals: catTotals, total: total, fmt: fmt),
        const SizedBox(height: 20),

        // ── Financial health ──────────────────────────────────────────────
        _SectionHeader(title: 'Financial Health'),
        const SizedBox(height: 12),
        _HealthCard(
          savingsRate: savingsRate,
          expenseRatio: expenseRatio,
          avgMonthly: avgMonthly,
          fmt: fmt,
        ),
        const SizedBox(height: 20),

        // ── Category analysis ─────────────────────────────────────────────
        _SectionHeader(title: 'Category Analysis'),
        const SizedBox(height: 12),
        _AnalysisCard(
          highest: highest,
          lowest: lowest,
          unwanted: unwanted,
          unwantedPct: unwantedPct,
          fmt: fmt,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── Reusable sub-widgets ──────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          color: _DS.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      );
}

// ── KPI card ──────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _KpiCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _DS.surface,
        border: Border.all(color: _DS.border),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: color.withOpacity(0.15),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: _DS.textSecondary, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis),
              ]),
        ),
      ]),
    );
  }
}

// ── Net balance card ──────────────────────────────────────────────────────────
class _NetBalanceCard extends StatelessWidget {
  final double balance, change;
  final NumberFormat fmt;

  const _NetBalanceCard(
      {required this.balance, required this.fmt, required this.change});

  @override
  Widget build(BuildContext context) {
    final positive = balance >= 0;
    final changePositive = change <= 0; // less spending = positive
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: positive
              ? [const Color(0xFF0D2818), const Color(0xFF1A3A28)]
              : [const Color(0xFF2D0F0F), const Color(0xFF3A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
            color: positive
                ? _DS.green.withOpacity(0.35)
                : _DS.red.withOpacity(0.35)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Net Balance',
                    style:
                        TextStyle(color: _DS.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(fmt.format(balance),
                    style: TextStyle(
                      color: positive ? _DS.green : _DS.red,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    )),
              ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('vs last week',
              style: TextStyle(color: _DS.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              changePositive
                  ? Icons.trending_down_rounded
                  : Icons.trending_up_rounded,
              color: changePositive ? _DS.green : _DS.red,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '${change.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                color: changePositive ? _DS.green : _DS.red,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ]),
        ]),
      ]),
    );
  }
}

// ── Compact stat row ──────────────────────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final String label, value;
  final IconData icon;

  const _StatRow(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: _DS.surface,
        border: Border.all(color: _DS.border),
      ),
      child: Row(children: [
        Icon(icon, color: _DS.blue, size: 18),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: _DS.textSecondary, fontSize: 13))),
        Text(value,
            style: const TextStyle(
                color: _DS.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ── Pie chart card ────────────────────────────────────────────────────────────
class _PieCard extends StatefulWidget {
  final Map<ExpenseCategory, double> catTotals;
  final double total;
  final NumberFormat fmt;

  const _PieCard(
      {required this.catTotals, required this.total, required this.fmt});

  @override
  State<_PieCard> createState() => _PieCardState();
}

class _PieCardState extends State<_PieCard> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final keys = widget.catTotals.keys.toList();
    final sections = List.generate(keys.length, (i) {
      final cat = keys[i];
      final val = widget.catTotals[cat]!;
      final color = _DS.catColor[cat]!;
      final isTouched = _touched == i;
      return PieChartSectionData(
        value: val,
        color: color,
        radius: isTouched ? 68 : 54,
        title: isTouched
            ? '${(val / widget.total * 100).toStringAsFixed(1)}%'
            : '',
        titleStyle: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
      );
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _DS.surface,
        border: Border.all(color: _DS.border),
      ),
      child: Column(children: [
        SizedBox(
          height: 200,
          child: Stack(alignment: Alignment.center, children: [
            PieChart(PieChartData(
              sections: sections,
              sectionsSpace: 3,
              centerSpaceRadius: 56,
              pieTouchData: PieTouchData(touchCallback: (event, response) {
                setState(() {
                  final idx =
                      response?.touchedSection?.touchedSectionIndex;
                  _touched =
                      (!event.isInterestedForInteractions || idx == null || idx < 0)
                          ? null
                          : idx;
                });
              }),
            )),
            // Centre display
            _touched != null
                ? Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_DS.catIcon[keys[_touched!]]!,
                        color: _DS.catColor[keys[_touched!]]!, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      widget.fmt
                          .format(widget.catTotals[keys[_touched!]]!),
                      style: TextStyle(
                        color: _DS.catColor[keys[_touched!]]!,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ])
                : const Text('Tap slice',
                    style: TextStyle(
                        color: _DS.textSecondary, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 12),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: widget.catTotals.entries.map((e) {
            final pct = widget.total > 0
                ? (e.value / widget.total * 100)
                : 0.0;
            return Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _DS.catColor[e.key])),
              const SizedBox(width: 5),
              Text(
                '${_DS.catLabel[e.key]} ${pct.toStringAsFixed(0)}%',
                style: const TextStyle(
                    color: _DS.textSecondary, fontSize: 12),
              ),
            ]);
          }).toList(),
        ),
      ]),
    );
  }
}

// ── Comparison bar chart card ─────────────────────────────────────────────────
class _ComparisonBarCard extends StatelessWidget {
  final double thisIncome, thisExpense, lastIncome, lastExpense;
  final double spendingChange;
  final NumberFormat fmt;

  const _ComparisonBarCard({
    required this.thisIncome,
    required this.thisExpense,
    required this.lastIncome,
    required this.lastExpense,
    required this.spendingChange,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = [thisIncome, thisExpense, lastIncome, lastExpense]
            .fold(0.0, (m, v) => v > m ? v : m) *
        1.25;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _DS.surface,
        border: Border.all(color: _DS.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Spending change',
                      style:
                          TextStyle(color: _DS.textSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(
                      spendingChange <= 0
                          ? Icons.trending_down_rounded
                          : Icons.trending_up_rounded,
                      color: spendingChange <= 0 ? _DS.green : _DS.red,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${spendingChange.abs().toStringAsFixed(1)}% vs last month',
                      style: TextStyle(
                        color: spendingChange <= 0 ? _DS.green : _DS.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ]),
                ]),
          ),
          // Legend
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _LegendDot(color: _DS.green, label: 'Income'),
            const SizedBox(height: 4),
            _LegendDot(color: _DS.red, label: 'Expense'),
          ]),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 160,
          child: BarChart(BarChartData(
            maxY: maxY == 0 ? 100 : maxY,
            alignment: BarChartAlignment.spaceAround,
            gridData: FlGridData(
              show: true,
              horizontalInterval: maxY == 0 ? 25 : maxY / 4,
              getDrawingHorizontalLine: (_) => FlLine(
                  color: _DS.border, strokeWidth: 0.8),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  const labels = [
                    'This\nIncome',
                    'This\nExpense',
                    'Last\nIncome',
                    'Last\nExpense'
                  ];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(labels[v.toInt()],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: _DS.textSecondary, fontSize: 10)),
                  );
                },
              )),
            ),
            barGroups: [
              _barGroup(0, thisIncome, _DS.green),
              _barGroup(1, thisExpense, _DS.red),
              _barGroup(2, lastIncome, _DS.green.withOpacity(0.4)),
              _barGroup(3, lastExpense, _DS.red.withOpacity(0.4)),
            ],
          )),
        ),
      ]),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) =>
      BarChartGroupData(x: x, barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 28,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        )
      ]);
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 5),
          Text(label,
              style:
                  const TextStyle(color: _DS.textSecondary, fontSize: 11)),
        ],
      );
}

// ── Financial health card ─────────────────────────────────────────────────────
class _HealthCard extends StatelessWidget {
  final double savingsRate, expenseRatio, avgMonthly;
  final NumberFormat fmt;

  const _HealthCard({
    required this.savingsRate,
    required this.expenseRatio,
    required this.avgMonthly,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _DS.surface,
        border: Border.all(color: _DS.border),
      ),
      child: Column(children: [
        _HealthRow(
          label: 'Savings Rate',
          value: '${savingsRate.toStringAsFixed(1)}%',
          progress: (savingsRate / 100).clamp(0.0, 1.0),
          color: _DS.green,
          icon: Icons.savings_rounded,
        ),
        const SizedBox(height: 14),
        _HealthRow(
          label: 'Expense Ratio',
          value: '${expenseRatio.toStringAsFixed(1)}%',
          progress: (expenseRatio / 100).clamp(0.0, 1.0),
          color: expenseRatio > 80 ? _DS.red : _DS.orange,
          icon: Icons.receipt_long_rounded,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(color: _DS.border, height: 1),
        ),
        Row(children: [
          const Icon(Icons.show_chart_rounded,
              color: _DS.blue, size: 18),
          const SizedBox(width: 10),
          const Expanded(
              child: Text('Monthly avg spending',
                  style:
                      TextStyle(color: _DS.textSecondary, fontSize: 13))),
          Text(fmt.format(avgMonthly),
              style: const TextStyle(
                  color: _DS.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final String label, value;
  final double progress;
  final Color color;
  final IconData icon;

  const _HealthRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: _DS.textSecondary, fontSize: 13))),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: _DS.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      );
}

// ── Category analysis card ────────────────────────────────────────────────────
class _AnalysisCard extends StatelessWidget {
  final MapEntry<String, double>? highest;
  final MapEntry<String, double>? lowest;
  final double unwanted, unwantedPct;
  final NumberFormat fmt;

  const _AnalysisCard({
    required this.highest,
    required this.lowest,
    required this.unwanted,
    required this.unwantedPct,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _DS.surface,
        border: Border.all(color: _DS.border),
      ),
      child: Column(children: [
        if (highest != null)
          _AnalysisRow(
            icon: Icons.arrow_circle_up_rounded,
            color: _DS.red,
            label: 'Highest: ${highest!.key}',
            value: fmt.format(highest!.value),
          ),
        if (highest != null && lowest != null)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: _DS.border, height: 1)),
        if (lowest != null)
          _AnalysisRow(
            icon: Icons.arrow_circle_down_rounded,
            color: _DS.green,
            label: 'Lowest: ${lowest!.key}',
            value: fmt.format(lowest!.value),
          ),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: _DS.border, height: 1)),
        _AnalysisRow(
          icon: Icons.warning_amber_rounded,
          color: unwantedPct > 30 ? _DS.red : _DS.orange,
          label: 'Unwanted (${unwantedPct.toStringAsFixed(1)}%)',
          value: fmt.format(unwanted),
        ),
        if (unwantedPct > 30) ...[
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _DS.red.withOpacity(0.10),
              border: Border.all(color: _DS.red.withOpacity(0.35)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded,
                  color: _DS.red, size: 15),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Unwanted spending exceeds 30% — consider reviewing discretionary expenses.',
                  style:
                      TextStyle(color: _DS.red, fontSize: 12, height: 1.4),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _AnalysisRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;

  const _AnalysisRow(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style:
                    const TextStyle(color: _DS.textSecondary, fontSize: 13))),
        Text(value,
            style: const TextStyle(
                color: _DS.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ]);
}

// ── Empty state card ──────────────────────────────────────────────────────────
class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _DS.surface,
          border: Border.all(color: _DS.border),
        ),
        child: Center(
            child: Text(message,
                style: const TextStyle(
                    color: _DS.textSecondary, fontSize: 14))),
      );
}

// ── Transaction tile ──────────────────────────────────────────────────────────
class _TxTile extends StatelessWidget {
  final TransactionModel tx;
  final NumberFormat fmt;

  const _TxTile({required this.tx, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isExpense = tx.transactionType == TransactionType.expense;
    final color =
        isExpense ? _DS.catColor[tx.expenseCategory]! : _DS.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: _DS.surface,
        border: Border.all(color: _DS.border),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: color.withOpacity(0.15),
          ),
          child: Icon(
            isExpense
                ? (_DS.catIcon[tx.expenseCategory] ??
                    Icons.receipt_rounded)
                : Icons.arrow_downward_rounded,
            color: color,
            size: 17,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title,
                    style: const TextStyle(
                        color: _DS.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(
                  '${tx.subCategory} • ${DateFormat('d MMM').format(tx.date)}',
                  style: const TextStyle(
                      color: _DS.textSecondary, fontSize: 11),
                ),
              ]),
        ),
        Text(
          '${isExpense ? '−' : '+'}${fmt.format(tx.amount)}',
          style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3),
        ),
      ]),
    );
  }
}