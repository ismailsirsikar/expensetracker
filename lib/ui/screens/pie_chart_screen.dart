import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants/enums.dart';
import '../../logic/providers/transaction_provider.dart';

class PieChartScreen extends StatefulWidget {
  const PieChartScreen({super.key});

  @override
  State<PieChartScreen> createState() => _PieChartScreenState();
}

class _PieChartScreenState extends State<PieChartScreen>
    with SingleTickerProviderStateMixin {
  int? _touchedIndex;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  static const Map<ExpenseCategory, _CategoryStyle> _categoryStyles = {
    ExpenseCategory.need: _CategoryStyle(
      color: Color(0xFF4FC3F7),
      gradient: [Color(0xFF0288D1), Color(0xFF4FC3F7)],
      icon: Icons.home_rounded,
      label: 'Needs',
    ),
    ExpenseCategory.unwanted: _CategoryStyle(
      color: Color(0xFFEF5350),
      gradient: [Color(0xFFC62828), Color(0xFFEF9A9A)],
      icon: Icons.remove_shopping_cart_rounded,
      label: 'Unwanted',
    ),
    ExpenseCategory.savings: _CategoryStyle(
      color: Color(0xFF66BB6A),
      gradient: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
      icon: Icons.savings_rounded,
      label: 'Savings',
    ),
    ExpenseCategory.fd: _CategoryStyle(
      color: Color(0xFFFFB74D),
      gradient: [Color(0xFFE65100), Color(0xFFFFB74D)],
      icon: Icons.account_balance_rounded,
      label: 'Fixed Deposit',
    ),
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final now = DateTime.now();
    final totals = provider.getCategoryTotalsForMonth(now.year, now.month)
        as Map<ExpenseCategory, double>;
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final total = totals.values.fold<double>(0, (s, v) => s + v);
    final monthLabel =
        DateFormat('MMMM yyyy').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: CustomScrollView(
        slivers: [
          // ── Collapsible AppBar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: const Color(0xFF0D1117),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: Color(0xFFE6EDF3)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expense Distribution',
                    style: TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    monthLabel,
                    style: const TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF161B22), Color(0xFF0D1117)],
                  ),
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: total == 0
                ? _buildEmptyState()
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _buildTotalCard(fmt, total),
                          const SizedBox(height: 24),
                          _buildChartCard(totals, total, fmt),
                          const SizedBox(height: 24),
                          _buildBreakdownList(totals, total, fmt),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Total Summary Card ────────────────────────────────────────────────────
  Widget _buildTotalCard(NumberFormat fmt, double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C2128), Color(0xFF161B22)],
        ),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Expenses',
                  style: TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  fmt.format(total),
                  style: const TextStyle(
                    color: Color(0xFFE6EDF3),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF0288D1), Color(0xFF4FC3F7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4FC3F7).withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.pie_chart_rounded,
                color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  // ── Pie Chart Card ────────────────────────────────────────────────────────
  Widget _buildChartCard(
      Map<ExpenseCategory, double> totals, double total, NumberFormat fmt) {
    final sections = _buildSections(totals, total);
    final touchedCategory = _touchedIndex != null
        ? totals.keys.toList()[_touchedIndex!]
        : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF161B22),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: SizedBox(
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 3,
                      centerSpaceRadius: 68,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            final idx =
                                response?.touchedSection?.touchedSectionIndex;
                            if (!event.isInterestedForInteractions ||
                                idx == null ||
                                idx < 0) {
                              _touchedIndex = null;
                              return;
                            }
                            _touchedIndex = idx;
                          });
                        },
                      ),
                    ),
                  ),
                  // Centre label
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: touchedCategory != null
                        ? _buildCentreDetail(
                            touchedCategory, totals[touchedCategory]!, total, fmt)
                        : _buildCentreDefault(totals.keys.length),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
      Map<ExpenseCategory, double> totals, double total) {
    final keys = totals.keys.toList();
    return List.generate(keys.length, (i) {
      final cat = keys[i];
      final val = totals[cat]!;
      final style = _categoryStyles[cat]!;
      final isTouched = _touchedIndex == i;
      final pct = total > 0 ? val / total * 100 : 0.0;

      return PieChartSectionData(
        value: val,
        color: style.color,
        radius: isTouched ? 76 : 62,
        title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        badgeWidget: isTouched
            ? null
            : val > 0
                ? _SmallDot(color: style.color)
                : null,
        badgePositionPercentageOffset: 0.98,
      );
    });
  }

  Widget _buildCentreDefault(int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Tap to',
          style: TextStyle(color: Color(0xFF8B949E), fontSize: 12),
        ),
        const Text(
          'explore',
          style: TextStyle(
            color: Color(0xFFE6EDF3),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCentreDetail(ExpenseCategory cat, double val, double total,
      NumberFormat fmt) {
    final style = _categoryStyles[cat]!;
    final pct = total > 0 ? val / total * 100 : 0.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(style.icon, color: style.color, size: 22),
        const SizedBox(height: 4),
        Text(
          '${pct.toStringAsFixed(1)}%',
          style: TextStyle(
            color: style.color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          style.label,
          style: const TextStyle(
            color: Color(0xFF8B949E),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ── Breakdown List ────────────────────────────────────────────────────────
  Widget _buildBreakdownList(
      Map<ExpenseCategory, double> totals, double total, NumberFormat fmt) {
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Breakdown',
          style: TextStyle(
            color: Color(0xFFE6EDF3),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(sorted.length, (i) {
          final entry = sorted[i];
          final style = _categoryStyles[entry.key]!;
          final pct = total > 0 ? entry.value / total : 0.0;

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 500 + i * 100),
            curve: Curves.easeOutCubic,
            builder: (context, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - v)),
                child: child,
              ),
            ),
            child: _CategoryRow(
              categoryStyle: style,
              value: entry.value,
              pct: pct,
              formattedValue: fmt.format(entry.value),
            ),
          );
        }),
      ],
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF161B22),
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: const Icon(Icons.pie_chart_outline_rounded,
                  color: Color(0xFF8B949E), size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'No expenses this month',
              style: TextStyle(
                color: Color(0xFFE6EDF3),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start tracking to see your\nspending breakdown here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category Row Widget ───────────────────────────────────────────────────────
class _CategoryRow extends StatelessWidget {
  final _CategoryStyle categoryStyle;
  final double value;
  final double pct;
  final String formattedValue;

  const _CategoryRow({
    required this.categoryStyle,
    required this.value,
    required this.pct,
    required this.formattedValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF161B22),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: categoryStyle.gradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: categoryStyle.color.withOpacity(0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(categoryStyle.icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryStyle.label,
                      style: const TextStyle(
                        color: Color(0xFFE6EDF3),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(pct * 100).toStringAsFixed(1)}% of total',
                      style: const TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formattedValue,
                style: TextStyle(
                  color: categoryStyle.color,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: const Color(0xFF30363D),
              valueColor:
                  AlwaysStoppedAnimation<Color>(categoryStyle.color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small dot badge on pie slice ──────────────────────────────────────────────
class _SmallDot extends StatelessWidget {
  final Color color;
  const _SmallDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ── Category Style Data Class ─────────────────────────────────────────────────
class _CategoryStyle {
  final Color color;
  final List<Color> gradient;
  final IconData icon;
  final String label;

  const _CategoryStyle({
    required this.color,
    required this.gradient,
    required this.icon,
    required this.label,
  });
}