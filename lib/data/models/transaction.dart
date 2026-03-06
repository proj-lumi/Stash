import 'package:isar/isar.dart';

import 'account.dart';
import 'category.dart';

part 'transaction.g.dart';

CollectionSchema get transactionSchema => TransactionSchema;

enum TransactionType {
  income,
  expense,
  transfer,
}

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  late double amount;

  @Index()
  late DateTime dateTime;

  @enumerated
  late TransactionType type;

  String? notes;

  /// Only for transfer: fee counted as expense in statistics.
  double? transferFee;

  final account = IsarLink<Account>();
  final category = IsarLink<Category>();
  final relatedAccount = IsarLink<Account>();

  Transaction();

  Transaction.create({
    required this.amount,
    required this.dateTime,
    required this.type,
    this.notes,
    this.transferFee,
  });
}
