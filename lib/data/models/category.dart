import 'package:isar/isar.dart';

part 'category.g.dart';

CollectionSchema get categorySchema => CategorySchema;

@collection
class Category {
  Id id = Isar.autoIncrement;

  late String name;

  /// Optional monthly budget; null means no budget set.
  double? monthlyBudget;

  Category();

  Category.create({
    required this.name,
    this.monthlyBudget,
  });
}
