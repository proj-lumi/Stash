import 'package:budget_app/data/database/database.dart';
import 'package:budget_app/data/models/transaction.dart';
import 'package:budget_app/data/repositories/account_repository.dart';
import 'package:budget_app/data/repositories/category_repository.dart';
import 'package:budget_app/data/repositories/transaction_repository.dart';
import 'package:budget_app/data/settings/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

final isarProvider = FutureProvider<Isar>((ref) => openDatabase());

final accountRepositoryProvider = Provider<AccountRepository?>((ref) {
  final isar = ref.watch(isarProvider);
    return isar.when(
    data: (i) => AccountRepository(i),
    loading: () => null,
    error: (_, stack) => null,
  );
});

final categoryRepositoryProvider = Provider<CategoryRepository?>((ref) {
  final isar = ref.watch(isarProvider);
    return isar.when(
    data: (i) => CategoryRepository(i),
    loading: () => null,
    error: (_, stack) => null,
  );
});

final transactionRepositoryProvider = Provider<TransactionRepository?>((ref) {
  final isar = ref.watch(isarProvider);
    return isar.when(
    data: (i) => TransactionRepository(i),
    loading: () => null,
    error: (_, stack) => null,
  );
});

final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) => SharedPreferences.getInstance());

final settingsRepositoryProvider = Provider<SettingsRepository?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.when(
    data: (p) => SettingsRepository(p),
    loading: () => null,
    error: (_, stack) => null,
  );
});

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings?>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  if (repo == null) return AppSettingsNotifier(null);
  return AppSettingsNotifier(repo)..load();
});

class AppSettingsNotifier extends StateNotifier<AppSettings?> {
  AppSettingsNotifier(this._repo) : super(_repo?.load());

  final SettingsRepository? _repo;

  void load() {
    final repo = _repo;
    if (repo != null) state = repo.load();
  }

  Future<void> setFontSize(double value) async {
    final repo = _repo;
    if (repo == null) return;
    await repo.saveFontSize(value);
    state = state?.copyWith(fontSize: value);
  }

  Future<void> setColorMode(ColorMode value) async {
    final repo = _repo;
    if (repo == null) return;
    await repo.saveColorMode(value);
    state = state?.copyWith(colorMode: value);
  }
}

/// Selected month for filtering transactions and statistics.
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

final transactionsForMonthProvider =
    StreamProvider.family<List<Transaction>, (int year, int month)>((ref, key) {
  final repo = ref.watch(transactionRepositoryProvider);
  if (repo == null) return Stream.value([]);
  return repo.watchTransactionsForMonth(key.$1, key.$2);
});
