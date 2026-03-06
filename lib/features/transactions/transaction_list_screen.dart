import 'package:budget_app/core/theme/app_theme.dart';
import 'package:budget_app/data/models/transaction.dart';
import 'package:budget_app/data/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final year = selectedMonth.year;
    final month = selectedMonth.month;
    final asyncList = ref.watch(transactionsForMonthProvider((year, month)));
    final repo = ref.watch(transactionRepositoryProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MonthSelector(
                  selected: selectedMonth,
                  onChanged: (d) =>
                      ref.read(selectedMonthProvider.notifier).state = d,
                ),
                const SizedBox(height: 16),
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ),
        asyncList.when(
          data: (list) {
            if (list.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No transactions this month',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _TransactionTile(
                    transaction: list[index],
                    onDelete: repo != null
                        ? () => repo.deleteTransaction(list[index].id)
                        : () {},
                  ),
                  childCount: list.length,
                ),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: Center(child: Text('Error: $e')),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
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

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.onDelete,
  });

  final Transaction transaction;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final type = transaction.type;
    final amount = transaction.amount;
    final dateTimeStr =
        DateFormat.yMMMd().add_jm().format(transaction.dateTime);
    final isIncome = type == TransactionType.income;
    final isTransfer = type == TransactionType.transfer;
    final amountColor = isIncome
        ? AppColors.income
        : isTransfer
            ? AppColors.transfer
            : AppColors.expense;
    final typeLabel =
        isIncome ? 'Income' : isTransfer ? 'Transfer' : 'Expense';

    return FutureBuilder(
      future: transaction.category.load(),
      builder: (context, snapshot) {
        final cat = transaction.category.value;
        final titleText = cat?.name ?? typeLabel;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: amountColor.withOpacity(0.2),
              child: Icon(
                isIncome
                    ? Icons.arrow_upward
                    : (isTransfer ? Icons.swap_horiz : Icons.arrow_downward),
                color: amountColor,
                size: 20,
              ),
            ),
            title: Text(titleText),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateTimeStr),
                if (transaction.notes != null && transaction.notes!.isNotEmpty)
                  Text(transaction.notes!),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '${isIncome ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: amountColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete transaction?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              onDelete();
                              Navigator.pop(ctx);
                            },
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
