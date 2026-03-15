import 'package:stash/core/theme/app_theme.dart';
import 'package:stash/data/models/account.dart';
import 'package:stash/data/models/category.dart';
import 'package:stash/data/models/transaction.dart';
import 'package:stash/data/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  TransactionType _type = TransactionType.expense;
  final _amountController = TextEditingController();
  Category? _selectedCategory;
  Account? _selectedAccount;
  Account? _fromAccount;
  Account? _toAccount;
  final _transferFeeController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _transferFeeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnack('Enter a valid amount');
      return;
    }

    final transactionRepo = ref.read(transactionRepositoryProvider);
    final accountRepo = ref.read(accountRepositoryProvider);
    final categoryRepo = ref.read(categoryRepositoryProvider);
    if (transactionRepo == null || accountRepo == null || categoryRepo == null) {
      _showSnack('Database not ready');
      return;
    }

    if (_type == TransactionType.expense) {
      if (_selectedAccount == null || _selectedCategory == null) {
        _showSnack('Select account and category');
        return;
      }
    } else if (_type == TransactionType.deposit) {
      if (_selectedAccount == null) {
        _showSnack('Select account');
        return;
      }
    } else {
      if (_fromAccount == null || _toAccount == null || _fromAccount?.id == _toAccount?.id) {
        _showSnack('Select different from/to accounts');
        return;
      }
    }

    final now = DateTime.now();
    final t = Transaction.create(
      amount: amount,
      dateTime: now,
      type: _type,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      transferFee: _type == TransactionType.transfer
          ? (double.tryParse(_transferFeeController.text) ?? 0)
          : null,
    );

    try {
      if (_type == TransactionType.expense) {
        await transactionRepo.addTransaction(
          t,
          account: _selectedAccount!,
          category: _selectedCategory,
        );
      } else if (_type == TransactionType.deposit) {
        await transactionRepo.addTransaction(
          t,
          account: _selectedAccount!,
        );
      } else {
        // transfer
        await transactionRepo.addTransaction(
          t,
          account: _fromAccount!,
          relatedAccount: _toAccount,
        );
        // if there's a fee, also record it as a separate expense
        final fee = double.tryParse(_transferFeeController.text) ?? 0;
        if (fee > 0) {
          // ensure there is a "Transfer Fee" category
          final feeCat = await categoryRepo.ensureCategory('Transfer Fee');
          final feeTx = Transaction.create(
            amount: fee,
            dateTime: now,
            type: TransactionType.expense,
            notes: 'Transfer fee',
          );
          await transactionRepo.addTransaction(
            feeTx,
            account: _fromAccount!,
            category: feeCat,
          );
        }
      }
      if (mounted) {
        _showSnack('Saved');
        _clearForm();
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e');
    }
  }

  void _clearForm() {
    setState(() {
      _amountController.clear();
      _transferFeeController.text = '0';
      _notesController.clear();
      _selectedCategory = null;
      _selectedAccount = null;
      _fromAccount = null;
      _toAccount = null;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _typeSelector(),
          const SizedBox(height: 24),
          _amountField(),
          const SizedBox(height: 16),
          if (_type == TransactionType.expense) _categoryField(),
          if (_type == TransactionType.expense) const SizedBox(height: 16),
          if (_type != TransactionType.transfer) _accountField(),
          if (_type != TransactionType.transfer) const SizedBox(height: 16),
          if (_type == TransactionType.transfer) ...[
            _transferFromTo(),
            const SizedBox(height: 16),
            _transferFeeField(),
            const SizedBox(height: 16),
          ],
          _notesField(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Save Transaction'),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _typeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _typeChip(TransactionType.expense, 'Expense'),
            _typeChip(TransactionType.deposit, 'Deposit'),
            _typeChip(TransactionType.transfer, 'Transfer'),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(TransactionType type, String label) {
    final selected = _type == type;
    return Expanded(
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: InkWell(
          onTap: () {
            setState(() {
              _type = type;
              _clearForm();
            });
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: selected ? AppColors.primaryForeground : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _amountField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Amount', style: Theme.of(context).textTheme.titleSmall),
                const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '₱',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryField() {
    final categoriesAsync = ref.watch(categoryRepositoryProvider);
    final list = categoriesAsync?.watchCategories();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Category', style: Theme.of(context).textTheme.titleSmall),
                const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            StreamBuilder<List<Category>>(
              stream: list?.asBroadcastStream() ?? Stream.value([]),
              builder: (context, snapshot) {
                final categories = snapshot.data ?? [];
                final value = categories
                    .where((c) => c.id == _selectedCategory?.id)
                    .firstOrNull ?? _selectedCategory;
                return DropdownButtonFormField<Category?>(
                  initialValue: value,
                  decoration: const InputDecoration(
                    hintText: 'Select category',
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Select category')),
                    ...categories.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedCategory = v),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountField() {
    final accountsAsync = ref.watch(accountRepositoryProvider);
    final list = accountsAsync?.watchAccounts();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Account', style: Theme.of(context).textTheme.titleSmall),
                const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            StreamBuilder<List<Account>>(
              stream: list?.asBroadcastStream() ?? Stream.value([]),
              builder: (context, snapshot) {
                final accounts = snapshot.data ?? [];
                final value = accounts
                    .where((a) => a.id == _selectedAccount?.id)
                    .firstOrNull ?? _selectedAccount;
                return DropdownButtonFormField<Account?>(
                  initialValue: value,
                  decoration: const InputDecoration(
                    hintText: 'Select account',
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Select account')),
                    ...accounts.map((a) => DropdownMenuItem(
                          value: a,
                          child: Text('${a.name} (${a.type})'),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedAccount = v),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _transferFromTo() {
    final accountsAsync = ref.watch(accountRepositoryProvider);
    final list = accountsAsync?.watchAccounts();
    return StreamBuilder<List<Account>>(
      stream: list?.asBroadcastStream() ?? Stream.value([]),
        builder: (context, snapshot) {
        final accounts = snapshot.data ?? [];
        final fromVal = accounts.where((a) => a.id == _fromAccount?.id).firstOrNull ?? _fromAccount;
        final toVal = accounts.where((a) => a.id == _toAccount?.id).firstOrNull ?? _toAccount;
        return Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('From account', style: Theme.of(context).textTheme.titleSmall),
                        const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    DropdownButtonFormField<Account?>(
                      initialValue: fromVal,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Select')),
                        ...accounts.map((a) => DropdownMenuItem(value: a, child: Text(a.name))),
                      ],
                      onChanged: (v) => setState(() => _fromAccount = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('To account', style: Theme.of(context).textTheme.titleSmall),
                        const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    DropdownButtonFormField<Account?>(
                      initialValue: toVal,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Select')),
                        ...accounts.map((a) => DropdownMenuItem(value: a, child: Text(a.name))),
                      ],
                      onChanged: (v) => setState(() => _toAccount = v),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _transferFeeField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Transfer fee', style: Theme.of(context).textTheme.titleSmall),
                const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '₱',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _transferFeeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _notesField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            hintText: 'Notes (optional)',
            alignLabelWithHint: true,
          ),
          maxLines: 2,
        ),
      ),
    );
  }
}
