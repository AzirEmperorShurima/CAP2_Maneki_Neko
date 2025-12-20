import 'package:finance_management_app/features/domain/translator/transaction_translator.dart';
import 'package:injectable/injectable.dart';

import '../../../core/common/bases/base_repository.dart';
import '../../../core/network/api_result.dart';
import '../../domain/entities/create_transaction_model.dart';
import '../../domain/entities/transaction_model.dart';
import '../../domain/repository/transaction_repository.dart';
import '../../domain/translator/budget_warning_translator.dart';
import '../remote/api_client.dart';
import '../requests/transaction_request.dart';
import '../response/create_transaction_response.dart';
import '../response/transaction_response.dart';

@LazySingleton(as: TransactionRepository)
class TransactionRepositoryImpl extends BaseRepository
    implements TransactionRepository {
  final ApiClient apiClient;

  TransactionRepositoryImpl(this.apiClient);

  @override
  Future<ApiResult<List<TransactionModel>?>> getTransactions(
    String? type,
    int? page,
    int? limit,
    DateTime? month,
    String? walletId,
  ) {
    return handleApiResponse<List<TransactionModel>?>(
      () async {
        final response = await apiClient.getTransactions(type, page, limit, month, walletId);

        final transactionResponses = response.getItems(
          TransactionResponse.fromJson,
          fromKey: 'transactions',
        );

        return transactionResponses
                ?.map((response) => response.toTransactionModel())
                .toList() ??
            [];
      },
    );
  }

  @override
  Future<ApiResult<CreateTransactionModel?>> createTransaction(
    TransactionRequest? request,
  ) {
    return handleApiResponse<CreateTransactionModel?>(
      () async {
        final response = await apiClient.createTransaction(request);

        final createResponse = response.getBody(
          CreateTransactionResponse.fromJson,
        );

        if (createResponse == null) {
          return null;
        }

        return CreateTransactionModel(
          transaction: createResponse.transaction?.toTransactionModel(),
          budgetWarnings: createResponse.budgetWarnings?.toBudgetWarningModel(),
        );
      },
    );
  }

  @override
  Future<ApiResult<CreateTransactionModel?>> updateTransaction(
    String id,
    TransactionRequest? request,
  ) {
    return handleApiResponse<CreateTransactionModel?>(
      () async {
        final response = await apiClient.updateTransaction(id, request);

        final createResponse = response.getBody(
          CreateTransactionResponse.fromJson,
        );

        if (createResponse == null) {
          return null;
        }

        return CreateTransactionModel(
          transaction: createResponse.transaction?.toTransactionModel(),
          budgetWarnings: createResponse.budgetWarnings?.toBudgetWarningModel(),
        );
      },
    );
  }

  @override
  Future<ApiResult<void>> deleteTransaction(String id) {
    return handleApiResponse<void>(
      () async {
        final response = await apiClient.deleteTransaction(id);
        return response;
      },
    );
  }
}
