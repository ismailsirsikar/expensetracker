import 'package:flutter/material.dart';
    import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants/enums.dart';
import '../../logic/providers/transaction_provider.dart';

class PieChartScreen extends StatelessWidget {
  const PieChartScreen({super.key});

  static const Map<ExpenseCategory, Color> _categoryColors = {
    ExpenseCategory.need: Colors.blue,
    ExpenseCategory.unwanted: Colors.red,
    ExpenseCategory.savings: Colors.green,
    ExpenseCategory.fd: Colors.orange,
  };

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final now = DateTime.now();
    final totals = provider.getCategoryTotalsForMonth(now.year, now.month) as Map<ExpenseCategory, double>;
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    final sections = totals.entries
        .map((e) => PieChartSectionData(
              value: e.value,
              color: _categoryColors[e.key],
              title: e.value > 0 ? '${e.value.toStringAsFixed(0)}' : '',
              radius: 60,
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Distribution'),
      ),
      body: Center(
        child: totals.values.fold<double>(0, (s, v) => s + v) == 0
            ? const Text('No expense data for this month')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 220,
                    width: 220,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: totals.keys.map((k) {
                      final val = totals[k]!;
                      return Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 12, height: 12, color: _categoryColors[k]),
                        const SizedBox(width: 6),
                        Text('${k.name}: ${fmt.format(val)}'),
                        const SizedBox(width: 12),
                      ]);
                    }).toList(),
                  )
                ],
              ),
      ),
    );
  }
}
