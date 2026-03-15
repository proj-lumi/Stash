import 'package:stash/core/theme/app_theme.dart';
import 'package:stash/data/models/account.dart';
import 'package:stash/data/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountRepo = ref.watch(accountRepositoryProvider);
    if (accountRepo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<Account>>(
      stream: accountRepo.watchAccounts().asBroadcastStream(),
      builder: (context, snapshot) {
        final accounts = snapshot.data ?? [];
        return FutureBuilder<double>(
          future: accountRepo.getTotalBalance(),
          builder: (context, totalSnap) {
            final total = totalSnap.data ?? 0;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TotalBalanceCard(total: total),
                  const SizedBox(height: 24),
                  Text(
                    'Your Accounts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...accounts.map((account) => _AccountTile(
                        account: account,
                        getBalance: () =>
                            accountRepo.getBalanceForAccount(account.id),
                        onDelete: () => _confirmDelete(
                          context,
                          account,
                          accountRepo,
                        ),
                      )),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _showAddAccount(context, ref, accountRepo),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Account'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    Account account,
    dynamic accountRepo,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text(
          'Delete "${account.name}"? Transactions will be kept but no longer linked to this account.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await accountRepo.deleteAccount(account.id);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Account deleted')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
  }

  void _showAddAccount(BuildContext context, WidgetRef ref, dynamic accountRepo) {
    final nameController = TextEditingController();
    String selectedType = 'Bank';
    final initialController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  label: RichText(
                    text: TextSpan(
                      text: 'Name',
                      style: Theme.of(ctx).textTheme.bodyMedium,
                      children: const [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  label: RichText(
                    text: TextSpan(
                      text: 'Type',
                      style: Theme.of(ctx).textTheme.bodyMedium,
                      children: const [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
                items: ['Cash', 'E-Wallet', 'Bank'].map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) selectedType = value;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: initialController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Initial balance', prefixText: '₱ '),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final initial =
                  double.tryParse(initialController.text) ?? 0;
              final account = Account.create(
                name: name,
                type: selectedType,
                initialBalance: initial,
              );
              await accountRepo.addAccount(account);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _TotalBalanceCard extends StatelessWidget {
  const _TotalBalanceCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Balance',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '₱${total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.getBalance,
    required this.onDelete,
  });

  final Account account;
  final Future<double> Function() getBalance;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          child: const Icon(Icons.account_balance_wallet,
              color: AppColors.primary, size: 22),
        ),
        title: Text(account.name),
        subtitle: Text(account.type),
        trailing: FutureBuilder<double>(
          future: getBalance(),
          builder: (context, snap) {
            final balance = snap.data ?? 0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₱${balance.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}