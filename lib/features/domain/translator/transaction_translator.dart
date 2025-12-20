import 'package:finance_management_app/features/data/response/transaction_response.dart';
import 'package:finance_management_app/features/domain/translator/category_translator.dart';
import 'package:finance_management_app/features/domain/translator/user_translator.dart';
import 'package:finance_management_app/features/domain/translator/wallet_translator.dart';
import '../entities/transaction_model.dart';

extension TransactionTranslator on TransactionResponse {
  TransactionModel toTransactionModel() {
    return TransactionModel(
      id: id,
      amount: amount,
      type: type,
      date: date,
      description: description,
      isShared: isShared,
      expenseFor: expenseFor,
      isOwner: isOwner,
      owner: owner?.toUserModel(),
      category: category?.toCategoryModel(),
      wallet: wallet?.toWalletModel(),
    );
  }
}
