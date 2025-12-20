import 'package:finance_management_app/core/network/api_result.dart';

import '../../data/requests/transaction_request.dart';
import '../entities/create_transaction_model.dart';
import '../entities/transaction_model.dart';

abstract class TransactionRepository {
  Future<ApiResult<List<TransactionModel>?>> getTransactions(
    String? type,
    int? page,
    int? limit,
    DateTime? month,
    String? walletId,
  );

  Future<ApiResult<CreateTransactionModel?>> createTransaction(
    TransactionRequest? request,
  );

  Future<ApiResult<CreateTransactionModel?>> updateTransaction(
    String id,
    TransactionRequest? request,
  );

  Future<ApiResult<void>> deleteTransaction(String id);
}
