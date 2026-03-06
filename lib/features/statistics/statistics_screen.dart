import 'package:budget_app/core/theme/app_theme.dart';
import 'package:budget_app/data/repositories/category_repository.dart';
import 'package:budget_app/data/providers/app_providers.dart';
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
          double income,
          double expense,
          Map<int, double> expenseByCategory,
          List<({int year, int month, double income, double expense})> trends,
        })>(
      future: Future.wait([
        transactionRepo.getMonthlyIncome(year, month),
        transactionRepo.getMonthlyExpense(year, month),
        transactionRepo.getMonthlyExpenseByCategory(year, month),
        transactionRepo.getMonthlyTrends(6),
      ]).then((r) => (
            income: r[0] as double,
            expense: r[1] as double,
            expenseByCategory: r[2] as Map<int, double>,
            trends: r[3] as List<({int year, int month, double income, double expense})>,
          )),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final net = data.income - data.expense;
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
                income: data.income,
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
          child: Text(
            monthName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
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
    required this.income,
    required this.expense,
    required this.net,
  });

  final double income;
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
                  Text(
                    'Income',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${income.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.income,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Expense',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${expense.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.expense,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Balance',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${net.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: net >= 0 ? AppColors.income : AppColors.expense,
                          fontWeight: FontWeight.bold,
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

  static const _colors = [
    AppColors.income,
    AppColors.primary,
    AppColors.accent,
    AppColors.secondary,
    AppColors.foregroundLight,
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

    final entries = expenseByCategory.entries.toList();
    final sections = <PieChartSectionData>[];
    for (var i = 0; i < entries.length; i++) {
      final pct = entries[i].value / total;
      sections.add(
        PieChartSectionData(
          value: entries[i].value,
          title: '${(pct * 100).toStringAsFixed(0)}%',
          color: _colors[i % _colors.length],
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
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
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _colors[e.key % _colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$name: \$${amount.toStringAsFixed(2)}',
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

  final List<({int year, int month, double income, double expense})> trends;

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
      (m, t) => [m, t.income, t.expense].reduce((a, b) => a > b ? a : b),
    );
    final maxVal = maxY * 1.2.clamp(1.0, double.infinity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (v, meta) => Text(
                      '\$${v.toInt()}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (i, meta) {
                      if (i.toInt() >= 0 && i.toInt() < trends.length) {
                        final t = trends[i.toInt()];
                        return Text(
                          '${t.month}/${t.year.toString().substring(2)}',
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (var i = 0; i < trends.length; i++) ...[
                  BarChartGroupData(
                    x: i * 2,
                    barRods: [
                      BarChartRodData(
                        toY: trends[i].income,
                        color: AppColors.income,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                    showingTooltipIndicators: [],
                  ),
                  BarChartGroupData(
                    x: i * 2 + 1,
                    barRods: [
                      BarChartRodData(
                        toY: trends[i].expense,
                        color: AppColors.expense,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                    showingTooltipIndicators: [],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
