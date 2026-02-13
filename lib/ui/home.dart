import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'screens/pie_chart_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/all_transactions_screen.dart';
import '../data/models/transaction_model.dart';
import '../core/constants/enums.dart';
import '../logic/providers/transaction_provider.dart';

// ── Shared design system (keep in sync with reports_screen.dart) ──────────────
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

  static const Map<ExpenseCategory, Color> catColor = {
    ExpenseCategory.need: Color(0xFF4FC3F7),
    ExpenseCategory.unwanted: Color(0xFFEF5350),
    ExpenseCategory.savings: Color(0xFF66BB6A),
    ExpenseCategory.fd: Color(0xFFFFB74D),
  };

  static const Map<ExpenseCategory, IconData> catIcon = {
    ExpenseCategory.need: Icons.home_rounded,
    ExpenseCategory.unwanted: Icons.remove_shopping_cart_rounded,
    ExpenseCategory.savings: Icons.savings_rounded,
    ExpenseCategory.fd: Icons.account_balance_rounded,
  };
}

// ─────────────────────────────────────────────────────────────────────────────

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final now = DateTime.now();
    final income = provider.totalIncomeForMonth(now.year, now.month);
    final expense = provider.totalExpenseForMonth(now.year, now.month);
    final balance = income - expense;
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final recent = provider.transactions.reversed.take(6).toList();
    final monthLabel = DateFormat('MMMM yyyy').format(now);

    return Scaffold(
      backgroundColor: _DS.bg,
      body: FadeTransition(
        opacity: _fade,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 64,
              pinned: true,
              backgroundColor: _DS.bg,
              surfaceTintColor: Colors.transparent,
              title: Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0288D1), Color(0xFF4FC3F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                const Text(
                  'ExpenseTracker',
                  style: TextStyle(
                    color: _DS.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ]),
              actions: [
                _AppBarAction(
                  icon: Icons.pie_chart_rounded,
                  tooltip: 'Pie Chart',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PieChartScreen())),
                ),
                _AppBarAction(
                  icon: Icons.bar_chart_rounded,
                  tooltip: 'Reports',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ReportsScreen())),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
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
            ),

            // ── Balance hero card ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _BalanceHeroCard(
                  balance: balance,
                  income: income,
                  expense: expense,
                  monthLabel: monthLabel,
                  fmt: fmt,
                ),
              ),
            ),

            // ── Quick nav strip ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  Expanded(
                    child: _QuickNavCard(
                      icon: Icons.pie_chart_rounded,
                      label: 'Distribution',
                      gradient: const [Color(0xFF0288D1), Color(0xFF4FC3F7)],
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PieChartScreen())),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickNavCard(
                      icon: Icons.bar_chart_rounded,
                      label: 'Reports',
                      gradient: const [Color(0xFF7B2FBE), Color(0xFFBB86FC)],
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ReportsScreen())),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickNavCard(
                      icon: Icons.add_rounded,
                      label: 'Add',
                      gradient: const [Color(0xFF1B5E20), Color(0xFF3FB950)],
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddTransactionScreen())),
                    ),
                  ),
                ]),
              ),
            ),

            // ── Section header ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                      color: _DS.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AllTransactionsScreen(),
                      ),
                    ),
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: _DS.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ]),
              ),
            ),

            // ── Transaction list ──────────────────────────────────────────
            recent.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _EmptyTransactions(),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final tx = recent[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration:
                                Duration(milliseconds: 350 + index * 70),
                            curve: Curves.easeOutCubic,
                            builder: (ctx, v, child) => Opacity(
                              opacity: v,
                              child: Transform.translate(
                                  offset: Offset(0, 14 * (1 - v)),
                                  child: child),
                            ),
                            child: _TxCard(
                              tx: tx,
                              fmt: fmt,
                              onDelete: () async {
                                final confirm = await _confirmDelete(context);
                                if (confirm != true) return;
                                await provider.deleteTransaction(tx.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Deleted "${tx.title}"'),
                                      backgroundColor: _DS.surface,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                        childCount: recent.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButton: _PrimaryFAB(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _DS.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: _DS.border)),
        title: const Text('Delete transaction',
            style: TextStyle(color: _DS.textPrimary, fontSize: 16)),
        content: const Text(
            'Are you sure you want to delete this transaction?',
            style: TextStyle(color: _DS.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: _DS.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('Delete', style: TextStyle(color: _DS.red)),
          ),
        ],
      ),
    );
  }
}

// ── Balance Hero Card ─────────────────────────────────────────────────────────
class _BalanceHeroCard extends StatelessWidget {
  final double balance, income, expense;
  final String monthLabel;
  final NumberFormat fmt;

  const _BalanceHeroCard({
    required this.balance,
    required this.income,
    required this.expense,
    required this.monthLabel,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final positive = balance >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: positive
              ? [const Color(0xFF0D2818), const Color(0xFF0D1117)]
              : [const Color(0xFF2D0F0F), const Color(0xFF0D1117)],
        ),
        border: Border.all(
          color: positive
              ? _DS.green.withOpacity(0.30)
              : _DS.red.withOpacity(0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (positive ? _DS.green : _DS.red).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(
            monthLabel,
            style: const TextStyle(
                color: _DS.textSecondary, fontSize: 13, letterSpacing: 0.2),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: (positive ? _DS.green : _DS.red).withOpacity(0.15),
              border: Border.all(
                  color: (positive ? _DS.green : _DS.red).withOpacity(0.40)),
            ),
            child: Text(
              positive ? 'Surplus' : 'Deficit',
              style: TextStyle(
                  color: positive ? _DS.green : _DS.red,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        const Text('Total Balance',
            style: TextStyle(color: _DS.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        Text(
          fmt.format(balance),
          style: TextStyle(
            color: positive ? _DS.green : _DS.red,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
              child: _BalanceStat(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Income',
                  value: fmt.format(income),
                  color: _DS.green)),
          Container(width: 1, height: 36, color: _DS.border),
          Expanded(
              child: _BalanceStat(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Expenses',
                  value: fmt.format(expense),
                  color: _DS.red,
                  alignRight: true)),
        ]),
      ]),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final bool alignRight;

  const _BalanceStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!alignRight) ...[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
        ],
        Column(
          crossAxisAlignment:
              alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                    letterSpacing: -0.3)),
          ],
        ),
        if (alignRight) ...[
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
        ],
      ],
    );

    return Padding(
      padding: EdgeInsets.only(
          left: alignRight ? 0 : 0, right: 0),
      child: Align(
        alignment:
            alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: content,
        ),
      ),
    );
  }
}

// ── Quick Nav Card ────────────────────────────────────────────────────────────
class _QuickNavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickNavCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _DS.surface,
          border: Border.all(color: _DS.border),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(
                  color: gradient.last.withOpacity(0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: _DS.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ── Transaction Card ──────────────────────────────────────────────────────────
class _TxCard extends StatelessWidget {
  final TransactionModel tx;
  final NumberFormat fmt;
  final VoidCallback onDelete;

  const _TxCard(
      {required this.tx, required this.fmt, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isExpense = tx.transactionType == TransactionType.expense;
    final color = isExpense
        ? (_DS.catColor[tx.expenseCategory] ?? _DS.red)
        : _DS.green;
    final icon = isExpense
        ? (_DS.catIcon[tx.expenseCategory] ?? Icons.receipt_rounded)
        : Icons.arrow_downward_rounded;

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false; // provider handles actual deletion
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _DS.red.withOpacity(0.15),
          border: Border.all(color: _DS.red.withOpacity(0.35)),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded,
            color: _DS.red, size: 22),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _DS.surface,
          border: Border.all(color: _DS.border),
        ),
        child: Row(children: [
          // Icon badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          // Title & subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title,
                    style: const TextStyle(
                      color: _DS.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    )),
                const SizedBox(height: 3),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: color.withOpacity(0.12),
                    ),
                    child: Text(
                      tx.subCategory,
                      style: TextStyle(
                          color: color, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('d MMM').format(tx.date),
                    style: const TextStyle(
                        color: _DS.textSecondary, fontSize: 11),
                  ),
                ]),
              ],
            ),
          ),
          // Amount
          Text(
            '${isExpense ? '−' : '+'}${fmt.format(tx.amount)}',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _DS.surface,
        border: Border.all(color: _DS.border),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _DS.card,
            border: Border.all(color: _DS.border),
          ),
          child: const Icon(Icons.receipt_long_rounded,
              color: _DS.textSecondary, size: 28),
        ),
        const SizedBox(height: 16),
        const Text('No transactions yet',
            style: TextStyle(
                color: _DS.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text('Tap + to add your first transaction',
            style: TextStyle(color: _DS.textSecondary, fontSize: 13)),
      ]),
    );
  }
}

// ── AppBar action button ──────────────────────────────────────────────────────
class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _AppBarAction(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _DS.surface,
              border: Border.all(color: _DS.border),
            ),
            child: Icon(icon, color: _DS.textSecondary, size: 18),
          ),
        ),
      ),
    );
  }
}

// ── Primary FAB ───────────────────────────────────────────────────────────────
class _PrimaryFAB extends StatelessWidget {
  final VoidCallback onTap;
  const _PrimaryFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF3FB950)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _DS.green.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}