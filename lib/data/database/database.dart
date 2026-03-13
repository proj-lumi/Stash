import 'package:stash/data/models/account.dart' as account_models;
import 'package:stash/data/models/category.dart' as category_models;
import 'package:stash/data/models/transaction.dart' as transaction_models;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

Future<Isar> openDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [
      account_models.accountSchema,
      category_models.categorySchema,
      transaction_models.transactionSchema,
    ],
    directory: dir.path,
  );
}
