import 'package:budget_app/core/theme/app_theme.dart';
import 'package:budget_app/data/models/category.dart';
import 'package:budget_app/data/providers/app_providers.dart';
import 'package:budget_app/data/repositories/category_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final year = selectedMonth.year;
    final month = selectedMonth.month;
    final categoryRepo = ref.watch(categoryRepositoryProvider);
    final transactionRepo = ref.watch(transactionRepositoryProvider);

    if (categoryRepo == null || transactionRepo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<Category>>(
      stream: categoryRepo.watchCategories().asBroadcastStream(),
      builder: (context, catSnapshot) {
        final categories = catSnapshot.data ?? [];
        return FutureBuilder<Map<int, double>>(
          future: transactionRepo.getMonthlyExpenseByCategory(year, month),
          builder: (context, expSnapshot) {
            final expenseByCategory = expSnapshot.data ?? {};
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
                  Text(
                    'Budget per Category',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...categories.map((cat) => _BudgetCard(
                        category: cat,
                        spent: expenseByCategory[cat.id] ?? 0,
                        onSetBudget: () => _showSetBudgetDialog(
                          context,
                          ref,
                          cat,
                          categoryRepo,
                        ),
                      )),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSetBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    Category category,
    CategoryRepository categoryRepo,
  ) {
    final controller = TextEditingController(
        text: category.monthlyBudget?.toStringAsFixed(2) ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set budget: ${category.name}'),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monthly budget',
            prefixText: '\$ ',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final value = double.tryParse(controller.text);
              if (value != null && value >= 0) {
                category.monthlyBudget = value;
                await categoryRepo.updateCategory(category);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Set Budget'),
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.selected, required this.onChanged});

  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final monthName = _format(selected);
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

  String _format(DateTime d) => DateFormat.yMMM().format(d);
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.category,
    required this.spent,
    required this.onSetBudget,
  });

  final Category category;
  final double spent;
  final VoidCallback onSetBudget;

  @override
  Widget build(BuildContext context) {
    final budget = category.monthlyBudget ?? 0.0;
    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final remaining = (budget - spent).clamp(0.0, double.infinity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.category,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '\$${spent.toStringAsFixed(2)} of \$${budget.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.borderLight.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1 ? AppColors.expense : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Remaining: \$${remaining.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onSetBudget,
              child: const Text('Set Budget'),
            ),
          ],
        ),
      ),
    );
  }
}
