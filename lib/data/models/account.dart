import 'package:isar/isar.dart';

part 'account.g.dart';

CollectionSchema get accountSchema => AccountSchema;

@collection
class Account {
  Id id = Isar.autoIncrement;

  late String name;

  /// e.g. "cash", "bank", "savings"
  late String type;

  double initialBalance = 0;

  Account();

  Account.create({
    required this.name,
    required this.type,
    this.initialBalance = 0,
  });
}
