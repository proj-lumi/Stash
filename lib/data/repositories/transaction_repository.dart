import 'package:budget_app/data/models/account.dart';
import 'package:budget_app/data/models/category.dart';
import 'package:budget_app/data/models/transaction.dart';
import 'package:isar/isar.dart';

class TransactionRepository {
  TransactionRepository(this._isar);

  final Isar _isar;

  /// Transactions for a given month, sorted by date descending.
  Stream<List<Transaction>> watchTransactionsForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    return _isar.transactions
        .filter()
        .dateTimeBetween(start, end, includeLower: true, includeUpper: true)
        .sortByDateTimeDesc()
        .watch(fireImmediately: true);
  }

  Future<List<Transaction>> getTransactionsForMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    return _isar.transactions
        .filter()
        .dateTimeBetween(start, end, includeLower: true, includeUpper: true)
        .sortByDateTimeDesc()
        .findAll();
  }

  Future<void> addTransaction(
    Transaction transaction, {
    required Account account,
    Category? category,
    Account? relatedAccount,
  }) async {
    await _isar.writeTxn(() async {
      transaction.account.value = account;
      if (category != null) transaction.category.value = category;
      if (relatedAccount != null) transaction.relatedAccount.value = relatedAccount;
      await _isar.transactions.put(transaction);
      await transaction.account.save();
      if (category != null) await transaction.category.save();
      if (relatedAccount != null) await transaction.relatedAccount.save();
    });
  }

  Future<void> updateTransaction(
    Transaction transaction, {
    Account? account,
    Category? category,
    Account? relatedAccount,
  }) async {
    await _isar.writeTxn(() async {
      if (account != null) transaction.account.value = account;
      if (category != null) transaction.category.value = category;
      if (relatedAccount != null) transaction.relatedAccount.value = relatedAccount;
      await _isar.transactions.put(transaction);
      await transaction.account.save();
      await transaction.category.save();
      await transaction.relatedAccount.save();
    });
  }

  Future<void> deleteTransaction(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.transactions.delete(id);
    });
  }

  /// Total income for month (type == income).
  Future<double> getMonthlyIncome(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    final list = await _isar.transactions
        .filter()
        .dateTimeBetween(start, end, includeLower: true, includeUpper: true)
        .typeEqualTo(TransactionType.income)
        .findAll();
    return list.fold<double>(0, (sum, t) => sum + t.amount);
  }

  /// Total expense for month: type == expense (amount) + transfer fees.
  Future<double> getMonthlyExpense(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    final list = await _isar.transactions
        .filter()
        .dateTimeBetween(start, end, includeLower: true, includeUpper: true)
        .findAll();
    double total = 0;
    for (final t in list) {
      if (t.type == TransactionType.expense) {
        total += t.amount;
      } else if (t.type == TransactionType.transfer && t.transferFee != null) {
        total += t.transferFee!;
      }
    }
    return total;
  }

  /// Expense per category for the month. Map: categoryId -> total amount.
  Future<Map<Id, double>> getMonthlyExpenseByCategory(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    final list = await _isar.transactions
        .filter()
        .dateTimeBetween(start, end, includeLower: true, includeUpper: true)
        .typeEqualTo(TransactionType.expense)
        .findAll();
    final map = <Id, double>{};
    for (final t in list) {
      await t.category.load();
      final cat = t.category.value;
      if (cat != null) {
        map[cat.id] = (map[cat.id] ?? 0) + t.amount;
      }
    }
    return map;
  }

  /// Income and expense totals for each of the previous N months (for bar chart).
  Future<List<({int year, int month, double income, double expense})>>
      getMonthlyTrends(int count) async {
    final now = DateTime.now();
    final results = <({int year, int month, double income, double expense})>[];
    for (var i = 0; i < count; i++) {
      var y = now.year;
      var m = now.month - i;
      while (m <= 0) {
        m += 12;
        y--;
      }
      final income = await getMonthlyIncome(y, m);
      final expense = await getMonthlyExpense(y, m);
      results.add((year: y, month: m, income: income, expense: expense));
    }
    return results.reversed.toList();
  }

  Future<void> deleteAllTransactions() async {
    await _isar.writeTxn(() async {
      await _isar.transactions.clear();
    });
  }
}
