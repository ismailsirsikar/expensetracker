import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'screens/pie_chart_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/reports_screen.dart';
import '../data/models/transaction_model.dart';
import '../core/constants/enums.dart';
import '../logic/providers/transaction_provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final now = DateTime.now();

    final income = provider.totalIncomeForMonth(now.year, now.month);
    final expense = provider.totalExpenseForMonth(now.year, now.month);
    final balance = income - expense;
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    final recent = provider.transactions.reversed.take(6).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PieChartScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.insert_chart_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Balance', style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(
                          fmt.format(balance),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Income: ${fmt.format(income)}', style: const TextStyle(color: Colors.green)),
                        Text('Expense: ${fmt.format(expense)}', style: const TextStyle(color: Colors.red)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Expanded(
              child: recent.isEmpty
                  ? const Center(child: Text('No transactions yet. Tap + to add one.'))
                  : ListView.separated(
                      itemCount: recent.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (context, index) {
                        final TransactionModel tx = recent[index];
                        final isExpense = tx.transactionType == TransactionType.expense;
                        return Dismissible(
                          key: Key(tx.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete transaction'),
                                content: const Text('Are you sure you want to delete this transaction?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                                ],
                              ),
                            );
                            if (confirm != true) return false;
                            await provider.deleteTransaction(tx.id);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted "${tx.title}"')));
                            return true;
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isExpense ? Colors.red.shade100 : Colors.green.shade100,
                              child: Icon(isExpense ? Icons.arrow_upward : Icons.arrow_downward, color: isExpense ? Colors.red : Colors.green),
                            ),
                            title: Text(tx.title),
                            subtitle: Text('${tx.subCategory} • ${tx.date.toLocal().toString().split(' ').first}'),
                            trailing: Text(
                              (isExpense ? '- ' : '+ ') + fmt.format(tx.amount),
                              style: TextStyle(color: isExpense ? Colors.red : Colors.green),
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
