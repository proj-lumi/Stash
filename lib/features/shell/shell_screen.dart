import 'package:stash/core/theme/app_theme.dart';
import 'package:stash/features/accounts/accounts_screen.dart';
import 'package:stash/features/budget/budget_screen.dart';
import 'package:stash/features/settings/settings_screen.dart';
import 'package:stash/features/statistics/statistics_screen.dart';
import 'package:stash/features/transactions/add_transaction_screen.dart';
import 'package:stash/features/transactions/transaction_list_screen.dart';
import 'package:stash/features/tutorial/tutorial_screen.dart';
import 'package:flutter/material.dart';

enum AppTab { transactions, add, statistics, budget, accounts }

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  AppTab _currentTab = AppTab.transactions;

  static const _tabs = [
    (AppTab.transactions, 'Transactions', Icons.receipt_long),
    (AppTab.add, 'Add', Icons.add_circle_outline),
    (AppTab.statistics, 'Statistics', Icons.pie_chart_outline),
    (AppTab.budget, 'Budget', Icons.account_balance_wallet_outlined),
    (AppTab.accounts, 'Accounts', Icons.credit_card),
  ];

  String get _title {
    switch (_currentTab) {
      case AppTab.transactions:
        return 'Transactions';
      case AppTab.add:
        return 'Add Transaction';
      case AppTab.statistics:
        return 'Statistics';
      case AppTab.budget:
        return 'Budget';
      case AppTab.accounts:
        return 'Accounts';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TutorialScreen(),
                ),
              );
            },
            tooltip: 'Tutorial',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: _buildBody(),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.light
                  ? AppColors.borderLight
                  : AppColors.borderDark,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _tabs.map((t) => _navItem(t.$1, t.$2, t.$3)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(AppTab tab, String label, IconData icon) {
    final isSelected = _currentTab == tab;
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;
    return InkWell(
      onTap: () => setState(() => _currentTab = tab),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentTab) {
      case AppTab.transactions:
        return const TransactionListScreen();
      case AppTab.add:
        return const AddTransactionScreen();
      case AppTab.statistics:
        return const StatisticsScreen();
      case AppTab.budget:
        return const BudgetScreen();
      case AppTab.accounts:
        return const AccountsScreen();
    }
  }
}

