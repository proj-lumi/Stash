import 'package:budget_app/data/models/category.dart';
import 'package:isar/isar.dart';

class CategoryRepository {
  CategoryRepository(this._isar);

  final Isar _isar;

  static const List<String> _seedNames = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Health',
    'Other',
  ];

  Stream<List<Category>> watchCategories() {
    return _isar.categorys.where().watch(fireImmediately: true);
  }

  Future<List<Category>> getCategories() => _isar.categorys.where().findAll();

  Future<Category?> getCategory(Id id) => _isar.categorys.get(id);

  Future<void> updateCategory(Category category) async {
    await _isar.writeTxn(() async {
      await _isar.categorys.put(category);
    });
  }

  Future<void> seedIfEmpty() async {
    final count = await _isar.categorys.count();
    if (count > 0) return;

    await _isar.writeTxn(() async {
      for (final name in _seedNames) {
        await _isar.categorys.put(Category.create(name: name));
      }
    });
  }

  /// Reseed: delete all and insert predefined categories (for Clear Data).
  Future<void> reseed() async {
    await _isar.writeTxn(() async {
      await _isar.categorys.clear();
      for (final name in _seedNames) {
        await _isar.categorys.put(Category.create(name: name));
      }
    });
  }
}
