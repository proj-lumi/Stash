import 'package:stash/core/theme/app_theme.dart';
import 'package:stash/data/repositories/category_repository.dart';
import 'package:stash/data/providers/app_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final year = selectedMonth.year;
    final month = selectedMonth.month;
    final transactionRepo = ref.watch(transactionRepositoryProvider);
    final categoryRepo = ref.watch(categoryRepositoryProvider);

    if (transactionRepo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<
        ({
          double deposit,
          double expense,
          Map<int, double> expenseByCategory,
          List<({int year, int month, double deposit, double expense})> trends,
        })>(
      future: Future.wait([
        transactionRepo.getMonthlyDeposit(year, month),
        transactionRepo.getMonthlyExpense(year, month),
        transactionRepo.getMonthlyExpenseByCategory(year, month),
        transactionRepo.getMonthlyTrends(6),
      ]).then((r) => (
            deposit: r[0] as double,
            expense: r[1] as double,
            expenseByCategory: r[2] as Map<int, double>,
            trends: r[3] as List<({int year, int month, double deposit, double expense})>,
          )),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final net = data.deposit - data.expense;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MonthSelector(
                selected: selectedMonth,
                onChanged: (d) =>
                    ref.read(selectedMonthProvider.notifier).state = d,
              ),
              const SizedBox(height: 16),
              _SummaryCard(
                deposit: data.deposit,
                expense: data.expense,
                net: net,
              ),
              const SizedBox(height: 24),
              Text(
                'Expenses by Category',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _ExpensePieChart(
                expenseByCategory: data.expenseByCategory,
                categoryRepo: categoryRepo,
              ),
              const SizedBox(height: 24),
              Text(
                'Monthly Trend',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _BarChartSection(trends: data.trends),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.selected, required this.onChanged});

  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat.yMMM().format(selected);
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            var y = selected.year;
            var m = selected.month - 1;
            if (m < 1) {
              m = 12;
              y--;
            }
            onChanged(DateTime(y, m));
          },
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              monthName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            var y = selected.year;
            var m = selected.month + 1;
            if (m > 12) {
              m = 1;
              y++;
            }
            final next = DateTime(y, m);
            if (next.isAfter(DateTime.now())) return;
            onChanged(next);
          },
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.deposit,
    required this.expense,
    required this.net,
  });

  final double deposit;
  final double expense;
  final double net;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Deposit',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '₱${deposit.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.deposit,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Expense',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '₱${expense.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Balance',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '₱${net.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: net >= 0 ? AppColors.deposit : AppColors.expense,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpensePieChart extends StatelessWidget {
  const _ExpensePieChart({
    required this.expenseByCategory,
    this.categoryRepo,
  });

  final Map<int, double> expenseByCategory;
  final CategoryRepository? categoryRepo;

  // Vibrant, distinct colors with good contrast
  static const _colors = [
    Color(0xFF236AB9), // Deep Blue
    Color(0xFF609CE1), // Sky Blue
    Color(0xFF2E7D32), // Forest Green
    Color(0xFFC62828), // Deep Red
    Color(0xFFF57C00), // Orange
    Color(0xFF6A1B9A), // Deep Purple
    Color(0xFF00796B), // Teal
    Color(0xFFD32F2F), // Bright Red
    Color(0xFF1565C0), // Cobalt
    Color(0xFFEF6C00), // Dark Orange
  ];

  @override
  Widget build(BuildContext context) {
    if (expenseByCategory.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No expenses this month')),
        ),
      );
    }

    final total =
        expenseByCategory.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No expenses this month')),
        ),
      );
    }

    // Determine text color based on brightness (white for dark mode, black for light mode)
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

    final entries = expenseByCategory.entries.toList();
    final sections = <PieChartSectionData>[];
    for (var i = 0; i < entries.length; i++) {
      final pct = entries[i].value / total;
      final color = _colors[i % _colors.length];
      sections.add(
        PieChartSectionData(
          value: entries[i].value,
          title: '${(pct * 100).toStringAsFixed(0)}%',
          color: color,
          radius: 60,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (categoryRepo != null)
              FutureBuilder<Map<int, String>>(
                future: _categoryNames(categoryRepo!, expenseByCategory.keys),
                builder: (context, snap) {
                  final names = snap.data ?? {};
                  return Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: entries.asMap().entries.map((e) {
                      final id = e.value.key;
                      final amount = e.value.value;
                      final name = names[id] ?? 'Category #$id';
                      final color = _colors[e.key % _colors.length];
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$name: ₱${amount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<Map<int, String>> _categoryNames(
      CategoryRepository repo, Iterable<int> ids) async {
    final map = <int, String>{};
    for (final id in ids) {
      final c = await repo.getCategory(id);
      if (c != null) map[id] = c.name;
    }
    return map;
  }
}

class _BarChartSection extends StatelessWidget {
  const _BarChartSection({
    required this.trends,
  });

  final List<({int year, int month, double deposit, double expense})> trends;

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No trend data')),
        ),
      );
    }

    final maxY = trends.fold<double>(
      0,
      (m, t) => [m, t.deposit, t.expense].reduce((a, b) => a > b ? a : b),
    );
    final maxVal = _getRoundMaxValue(maxY * 1.2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final i = group.x.toInt();
                        if (i < 0 || i >= trends.length) return null;
                        final label = rodIndex == 0 ? 'Deposit' : 'Expense';
                        return BarTooltipItem(
                          '$label\n₱${rod.toY.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: maxVal > 0 ? maxVal : 1,
                        getTitlesWidget: (v, meta) {
                          if (v == 0 || v == maxVal) {
                            return Text(
                              '₱${v.toInt()}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (i, meta) {
                          final idx = i.toInt();
                          if (idx >= 0 && idx < trends.length) {
                            final t = trends[idx];
                            final d = DateTime(t.year, t.month);
                            return Text(
                              DateFormat.MMM().format(d),
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (var i = 0; i < trends.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: trends[i].deposit,
                            color: AppColors.deposit,
                            width: 8,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                          BarChartRodData(
                            toY: trends[i].expense,
                            color: AppColors.primary,
                            width: 8,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: AppColors.deposit, label: 'Deposit'),
                const SizedBox(width: 24),
                _LegendItem(color: AppColors.primary, label: 'Expense'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getRoundMaxValue(double value) {
    if (value <= 0) return 100;
    if (value <= 100) {
      return ((value / 10).ceil() * 10).toDouble();
    } else if (value <= 1000) {
      return ((value / 50).ceil() * 50).toDouble();
    } else {
      return ((value / 100).ceil() * 100).toDouble();
    }
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
