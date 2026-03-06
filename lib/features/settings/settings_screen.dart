import 'package:budget_app/core/theme/app_theme.dart';
import 'package:budget_app/data/providers/app_providers.dart';
import 'package:budget_app/data/settings/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Font size',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['Small', 'Medium', 'Large'].asMap().entries.map((e) {
                        final size = e.key == 0
                            ? 12.0
                            : e.key == 1
                                ? 16.0
                                : 20.0;
                        final current = settings?.fontSize ?? 16.0;
                        final isSelected = (e.key == 0 && current <= 14) ||
                            (e.key == 1 && current > 14 && current < 18) ||
                            (e.key == 2 && current >= 18);
                        return ChoiceChip(
                          label: Text(e.value),
                          selected: isSelected,
                          onSelected: (_) => notifier.setFontSize(size),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                title: const Text('Dark mode'),
                value: settings?.colorMode == ColorMode.dark,
                onChanged: (v) {
                  notifier.setColorMode(v ? ColorMode.dark : ColorMode.light);
                },
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                title: const Text(
                  'Clear all data',
                  style: TextStyle(
                    color: AppColors.destructive,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(Icons.delete_outline,
                    color: AppColors.destructive),
                onTap: () => _confirmClearData(context, ref),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget App',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Offline budgeting. No account, no cloud. Your data stays on this device.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearData(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This will delete all transactions and accounts, and reset categories to defaults. Settings will be kept. This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final transactionRepo = ref.read(transactionRepositoryProvider);
    final accountRepo = ref.read(accountRepositoryProvider);
    final categoryRepo = ref.read(categoryRepositoryProvider);

    if (transactionRepo == null || accountRepo == null || categoryRepo == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Database not ready')));
      }
      return;
    }

    await transactionRepo.deleteAllTransactions();
    await accountRepo.deleteAllAccounts();
    await categoryRepo.reseed();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')));
    }
  }
}
